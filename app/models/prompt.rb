# frozen_string_literal: true

class Prompt < ApplicationRecord
  include Markdownable
  include Taggable
  include Ticketable
  include Moderatable
  MIN_CONTENT_LENGTH = 10

  belongs_to :user

  has_many :prompt_tags, dependent: :destroy
  has_many :tags, through: :prompt_tags, :counter_cache => true

  enum status: {
    draft: 0,
    locked: 1,
    posted: 2
  }

  before_validation :set_initial_bumped, on: :create

  validates_with PromptContentValidator
  validates :status, inclusion: { in: Prompt.statuses }
  validate :can_bump, on: :update
  validate :can_spend, on: %i[create update]

  after_create :spend_ticket

  default_scope { order(bumped_at: :desc) }

  def mark_starter
    markdown_concern(starter)
  end

  def mark_ooc
    markdown_concern(ooc)
  end

  def bumpable?
    diff_in_seconds = Time.zone.at(DateTime.now) - bumped_at_was
    diff_in_seconds += 1.second # a surprise tool to help us later
    seconds_in_a_day = 24 * 60 * 60

    diff_in_seconds / seconds_in_a_day >= 1
  end

  def bump!
    self.bumped_at = DateTime.now

    return false unless save

    spend_ticket
  end

  # Should really only be called from controller
  # @param tag_params [Object] Permitted tag_params
  def add_tags(tag_params)
    # We want to store a copy of the old tags
    old_tags = tags.map do |old_tag|
      old_tag
    end

    begin
      self.prompt_tags = PromptTag.from_tag_params(tag_params) # RecordInvalid thrown here
      process_tags
    rescue ActiveRecord::RecordInvalid
      # If this block is run, something's(enabled flag?) probably wrong with one of the add_meta_tags tags
      self.tags = old_tags
      return false
    end

    true
  end

  # This is seprate from add_tags to make testing/experimenting easier
  def process_tags
    collapse_list

    add_meta_tags

    remove_disabled_tags_from_prompts
  end

  def set_initial_bumped
    self.bumped_at = DateTime.now
  end

  private

  # For validation
  def can_bump
    return unless bumped_at_changed?

    errors.add(:bump, "You must wait until #{bumped_at + 1.day} to bump this prompt.") unless bumpable?
  end

  def spend_ticket
    Ticket.spend(self)
  end
end
