# frozen_string_literal: true

class Character < ApplicationRecord
  include Taggable
  include Ticketable
  include Reportable
  include Alertable
  include Auditable
  MIN_CONTENT_LENGTH = 10
  MAX_CONTENT_LENGTH = 65_536

  belongs_to :user
  belongs_to :pseudonym, optional: true

  has_many :object_tags, as: :object, dependent: :destroy
  has_many :tags, through: :object_tags

  has_many :object_characters, dependent: :destroy
  has_many :objects, through: :object_characters

  scope :shadowbanned, -> { joins(:user).where(user: { shadowbanned: true }) }
  scope :not_shadowbanned, -> { joins(:user).where(user: { shadowbanned: false }) }

  enum :status, {
    draft: 0,
    locked: 1,
    posted: 2
  }, validate: true

  enum :tag_status, {
    dirty: 0,
    clean: 1
  }, validate: true

  validates_with CharacterContentValidator
  validates :color, format: { with: /\A#(?:[A-F0-9]{3}){1,2}\z/i }
  validate :can_spend, on: %i[create update], unless: -> { Current.user&.admin? && Current.user != user }
  validate :authorization, on: %i[create update]

  after_create :spend_ticket, unless: -> { Current.user&.admin? && Current.user != user }

  default_scope { order(updated_at: :desc) }

  has_snapshot_children do
    instance = self.class.includes(:object_tags, :object_characters).find(id)
    {
      object_tags: instance.object_tags,
      object_characters: instance.object_characters
    }
  end

  def alertable_fields
    %i[description]
  end

  # Should really only be called from controller
  # @param tag_params [Object] Permitted tag_params
  def add_tags(tag_params)
    # We want to store a copy of the old tags
    old_tags = tags.map do |old_tag|
      old_tag
    end

    begin
      self.object_tags = ObjectTag.from_tag_params(tag_params) # RecordInvalid thrown here
      # polymorphic relations are weird, so we have to reload for the above to take effect
      reload unless new_record?

      # logger.debug(object_tags.map { |v| "test #{v.tag.tag_type} - #{v.tag.name}" })
      # logger.debug tags.pluck(:name)
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

    set_managed

    remove_disabled_tags_from_prompts

    self.tag_status = :clean
    save
  end

  private

  def spend_ticket
    Ticket.spend(self)
  end

  def authorization
    return unless !pseudonym.nil? && pseudonym.user.id != user.id

    errors.add(:pseudonym, 'You are not authorized to do that.')
  end
end
