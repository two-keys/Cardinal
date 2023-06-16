# frozen_string_literal: true

class Tag < ApplicationRecord
  MAX_SYNONYM_DEPTH = 1
  MAX_RECURSION_DEPTH = 25

  has_ancestry

  has_many :duplicates, class_name: 'Tag', foreign_key: 'synonym_id', inverse_of: 'synonym', dependent: :destroy
  belongs_to :synonym, class_name: 'Tag', optional: true
  before_save :fix_synonym

  has_many :object_tags, dependent: :destroy
  has_many :objects, through: :object_tags

  scope :with_public, -> { where(enabled: true) }

  validates :name, presence: true, length: { maximum: 254 }
  validates :tag_type, presence: true, length: { maximum: 25 }, inclusion: CardinalSettings::Tags.types.keys

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

  def lower
    name.downcase
  end

  # Automatically called before saving a tag to the DB
  def fix_synonym
    return if synonym.nil? # doesn't need fixing

    return if synonym.synonym.nil? # if a tag's synonym doesn't have a synonym, it's fine

    chain = Tag.chain_synonym(self, nil)
    self.synonym = chain
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

      search_tags << Tag.find_or_create_by!(name:, tag_type:, polarity:)
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
            temp_tag = Tag.find_or_create_by!(name: tag_name, tag_type: type, polarity:)
            new_tags << temp_tag
          end
        end
      end
    end

    new_tags.uniq(&:id)
  end

  private

  def polarity_must_match_tag_type
    return if CardinalSettings::Tags.polarities_for(tag_type).include? polarity

    errors.add(:polarity, 'Must be a valid polarity for the given tag type')
  end
end
