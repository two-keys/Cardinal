# frozen_string_literal: true

require 'csv'

class Tag < ApplicationRecord # rubocop:disable Metrics/ClassLength
  MAX_SYNONYM_DEPTH = 1
  MAX_RECURSION_DEPTH = 25

  has_ancestry

  has_many :duplicates, class_name: 'Tag', foreign_key: 'synonym_id', inverse_of: 'synonym', dependent: :destroy
  belongs_to :synonym, class_name: 'Tag', optional: true
  before_validation :set_lower
  before_save :fix_synonym
  before_update :dirty_taggables

  has_many :object_tags, dependent: :destroy
  has_many :objects, through: :object_tags
  has_many :filters, as: :target, dependent: :destroy

  scope :with_public, -> { where(enabled: true) }

  validates :name, presence: true, length: { maximum: 64 }
  validates :lower, presence: true, length: { maximum: 64 }, uniqueness: { scope: %i[polarity tag_type] }
  validates :tag_type, presence: true, length: { maximum: 25 }, inclusion: TagSchema.allowed_types

  validates :polarity, presence: true
  validate :polarity_must_match_tag_type

  validates :enabled, inclusion: [true, false]

  def useage_count
    object_tags.count
  end

  # Compares two tags by comparing their lowercase versions
  def identical?(other)
    lower == other.lower
  end

  # An extended version of find_or_create_by that takes into account
  # lowercase versions of tags
  # @param polarity [string] tag's polarity
  # @param tag_type [string] tag's type
  # @param name Tag's display name. Compared against existing tags with .downcase
  # @return [Tag] Either a new tag or the existing tag matching polarity, tag_type, and name.
  def self.find_or_create_with_downcase(polarity:, tag_type:, name:)
    temp_tag = Tag.find_by(
      polarity:, tag_type:, lower: name.downcase
    )

    if temp_tag.nil?
      temp_tag = Tag.create!(
        polarity:, tag_type:, name:
      )
    end

    temp_tag
  end

  # Automatically called before saving a tag to the DB
  def fix_synonym
    return if synonym.nil? # doesn't need fixing

    return if synonym.synonym.nil? # if a tag's synonym doesn't have a synonym, it's fine

    chain = Tag.chain_synonym(self, nil)
    self.synonym = chain
  end

  def to_csv
    CSV.generate do |csv|
      csv << attributes.values
    end
  end

  # Recursively gets synonyms, up to MAX_RECURSION_DEPTH.
  # Do not call this to get a tag's synonym, just use the default synonym getter.
  # @param tag [self] The tag to recurse into the synonyms of.
  # @param in_depth [Integer] Staring depth. Call as nil outside of function.
  def self.chain_synonym(tag, in_depth)
    depth = in_depth || 1

    next_syn = tag.synonym

    # We don't want to go past the max recursion depth and be caught in an infinite loop
    return next_syn if next_syn.synonym.nil? || depth == Tag::MAX_RECURSION_DEPTH

    depth += 1
    chain_synonym next_syn, depth
  end

  # @return [Array<Tag>]
  def self.from_search_params(search_params)
    search_tags = []

    tag_strings = search_params.split(',')
    tag_strings.each do |tag_string|
      pieces = tag_string.split(':', 3)

      polarity = pieces[0]
      tag_type = pieces[1]
      name = pieces[2].strip

      search_tags << Tag.find_or_create_with_downcase(
        polarity:,
        tag_type:,
        name:
      )

      logger.debug search_tags.last
    end

    # Let @prompt.save handle the bulk of processing/validating tags
    # The only thing we should worry about here is not passing duplicate tags
    search_tags.uniq(&:id)
  end

  # @return [Array<Tag>]
  def self.from_tag_params(tag_params)
    new_tags = []
    tag_params.each do |polarity, polarity_hash|
      # for each polarity
      polarity_hash.each do |type, type_tags_array|
        # for each tag_type under each polarity

        # We want to assume every entry in type_tags_array CAN be a comma delimited list of tags
        # This means we use the same processing strategy for checklist tags as we do for fill_ins
        type_tags_array.each do |tag_string|
          list_from_split = tag_string.gsub("\n", ',').split(',')
          list_from_split.map! do |raw_tag|
            # strip handles \t, \n, \r, and spaces AROUND a string
            processed_tag = raw_tag.strip

            processed_tag
          end
          list_from_split.compact_blank! # strip might've resulted in empty tags

          list_from_split.each do |tag_name|
            temp_tag = Tag.find_or_create_with_downcase(
              polarity:,
              tag_type: type,
              name: tag_name
            )
            new_tags << temp_tag
          end
        end
      end
    end

    new_tags.uniq(&:id)
  end

  private

  def polarity_must_match_tag_type
    return if TagSchema.allowed_types_for(polarity).include?(tag_type)

    errors.add(:polarity, 'Must be a valid polarity for the given tag type')
  end

  def dirty_taggables
    # only cascade if something important changed
    return unless synonym_changed? || ancestry_changed? || enabled_changed?

    Prompt.where(id: ObjectTag.where(tag: self)
          .select(:object_id))
          .update_all(tag_status: :dirty) # rubocop:disable Rails/SkipsModelValidations

    Character.where(id: ObjectTag.where(tag: self)
             .select(:object_id))
             .update_all(tag_status: :dirty) # rubocop:disable Rails/SkipsModelValidations
  end

  def set_lower
    self.lower = name.downcase
  end
end
