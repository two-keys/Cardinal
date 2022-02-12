# frozen_string_literal: true

class Tag < ApplicationRecord
  MAX_SYNONYM_DEPTH = 1
  MAX_RECURSION_DEPTH = 25

  has_ancestry

  has_many :duplicates, class_name: 'Tag', foreign_key: 'synonym_id', inverse_of: 'synonym', dependent: :destroy
  belongs_to :synonym, class_name: 'Tag', optional: true
  before_save :fix_synonym

  has_many :prompt_tags, dependent: :destroy
  has_many :prompts, through: :prompt_tags

  scope :with_public, -> { where(enabled: true) }

  validates :name, presence: true, length: { maximum: 254 }
  validates :tag_type, presence: true, length: { maximum: 25 }, inclusion: CardinalSettings::Tags.types.keys

  validates :polarity, presence: true
  validate :polarity_must_match_tag_type

  validates :enabled, inclusion: [true, false]

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

  private

  def polarity_must_match_tag_type
    return if CardinalSettings::Tags.polarities_for(tag_type).include? polarity

    errors.add(:polarity, 'Must be a valid polarity for the given tag type')
  end
end
