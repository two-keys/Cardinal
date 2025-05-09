# frozen_string_literal: true

class Prompt < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Markdownable
  include Taggable
  include Characterized
  include Ticketable
  include Reportable
  include Alertable
  include Auditable
  MIN_CONTENT_LENGTH = 10
  MAX_CONTENT_LENGTH = 65_536
  BUMP_WAIT_TIME = 2.days

  belongs_to :user
  belongs_to :pseudonym, optional: true

  has_many :object_tags, as: :object, dependent: :destroy
  has_many :object_characters, as: :object, dependent: :destroy
  has_many :tags, through: :object_tags
  has_many :characters, through: :object_characters

  has_many :chats, dependent: :nullify

  enum :status, {
    draft: 0,
    locked: 1,
    posted: 2
  }, validate: true

  enum :tag_status, {
    dirty: 0,
    clean: 1
  }, validate: true

  before_validation :set_initial_bumped, on: :create

  validates_with PromptContentValidator
  validates :default_slots, numericality: { only_integer: true, greater_than_or_equal_to: 2 }
  validates :color, format: { with: /\A#(?:[A-F0-9]{3}){1,2}\z/i }
  validate :can_bump, on: :update
  validate :can_spend, on: %i[create], unless: -> { Current.user&.admin? && Current.user != user }
  validate :can_spend_up, on: %i[update], unless: -> { Current.user&.admin? && Current.user != user }
  validate :authorization, on: %i[create update]

  after_create :spend_ticket, unless: -> { Current.user&.admin? && Current.user != user }

  default_scope { order(bumped_at: :desc) }

  scope :shadowbanned, -> { joins(:user).where(user: { shadowbanned: true }) }
  scope :not_shadowbanned, -> { joins(:user).where(user: { shadowbanned: false }) }

  has_snapshot_children do
    instance = self.class.includes(:object_tags, :object_characters).find(id)
    {
      object_tags: instance.object_tags,
      object_characters: instance.object_characters
    }
  end

  def alertable_fields
    %i[starter ooc]
  end

  # Answers a prompt, creating a new chat
  def answer(as_user)
    @chat = Chat.new
    @chat.prompt = self
    @chat.chat_users << if managed?
                          ChatUser.new(user: as_user.shadowbanned? ? User.find(0) : user, role: ChatUser.roles[:chat_admin], color:) # prompt owner # rubocop:disable Layout/LineLength
                        else
                          ChatUser.new(user: as_user.shadowbanned? ? User.find(0) : user, color:)
                        end
    @chat.chat_users << ChatUser.new(user: as_user)

    @chat.messages << Message.new(content: ooc) if ooc.present?
    @chat.messages << Message.new(content: starter, color:) if starter.present?

    @chat
  end

  def bumpable?
    return false if bumped_at_was.nil?

    (Time.zone.now - bumped_at_was) > BUMP_WAIT_TIME
  end

  def bump!
    self.bumped_at = DateTime.now

    return false unless save
    return true if Current.user&.admin? && Current.user != user

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

  def set_initial_bumped
    self.bumped_at = DateTime.now
  end

  private

  # For validation
  def can_bump
    return unless bumped_at_changed?

    errors.add(:bump, "You must wait until #{bumped_at + 1.day} to bump this prompt.") unless bumpable?
  end

  def can_spend_up
    return unless bumped_at_changed?

    can_spend
  end

  def spend_ticket
    Ticket.spend(self)
  end

  def authorization
    return unless !pseudonym.nil? && pseudonym.user.id != user.id

    errors.add(:pseudonym, 'You are not authorized to do that.')
  end
end
