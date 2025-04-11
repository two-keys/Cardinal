# frozen_string_literal: true

class ChatUser < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Entitlementable

  belongs_to :user
  belongs_to :pseudonym, optional: true
  belongs_to :chat

  enum :status, {
    ongoing: 0,
    unanswered: 1,
    unread: 2,
    ended: 3,
    ended_viewed: 4
  }

  enum :role, {
    chat_user: 0,
    chat_moderator: 1,
    chat_admin: 2
  }

  default_scope { includes(:chat, :user) }

  before_validation :generate_icon, on: :create
  after_create_commit :generate_icon_entitlement

  validates :user_id, uniqueness: { scope: :chat_id }
  validates :icon, uniqueness: { scope: :chat_id }, length: { maximum: 4000 }, presence: true
  validates :color, format: { with: /\A#(?:[A-F0-9]{3}){1,2}\z/i }
  validate :check_icon, on: :update
  validate :authorization, on: %i[create update]

  attribute :skip_check_icon

  ## This is kind of forced to have high complexity, there's a lot that
  ## goes into determining the user's notification status.
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def viewed!
    return if ended_viewed?

    if ended?
      self.status = 'ended_viewed'
    elsif unanswered?
      self.status = 'ongoing' if chat.messages.last.user == user || chat.messages.last.user.nil?
    else
      self.status = 'ongoing' if chat.messages.last.user == user || chat.messages.last.user.nil?
      self.status = 'unanswered' if chat.messages.last.user != user && !chat.messages.last.user.nil?
    end
    save!
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def icon_entitlements
    user.entitlements.where(flag: 'emoji', object_id: nil, object_type: nil)
        .or(user.entitlements.where(flag: 'emoji', object: self))
  end

  def permission_entitlements
    user.entitlements.where(flag: 'permission', object_id: nil, object_type: nil)
        .or(user.entitlements.where(flag: 'permission', object: self))
  end

  def available_icons
    emoji_entitlements = icon_entitlements
    emoji_entitlements.map(&:data)
  end

  def change_icon(new_icon, force: false, grant: false)
    prev_icon = icon
    return false unless prev_icon != new_icon

    self.skip_check_icon = force
    self.icon = new_icon
    save!
    self.skip_check_icon = false

    if grant
      entitlement = Entitlement.find_or_create_by(object: self, flag: 'emoji', data: new_icon)
      user.entitlements << entitlement
    end

    message_content = "#{icon_for prev_icon} is now #{icon_for icon}."
    chat.messages << Message.new(content: message_content)

    true
  end

  def generate_entitlement
    if chat.chat_users.count == 1
      owner_entitlement = Entitlement.find_or_create_by(object: self, flag: 'permission', data: 'owner')
      user.entitlements << owner_entitlement if user.entitlements.exclude?(owner_entitlement)
    end
    read_entitlement = Entitlement.find_or_create_by(object: self, flag: 'permission', data: 'read')
    user.entitlements << read_entitlement if user.entitlements.exclude?(read_entitlement)
    write_entitlement = Entitlement.find_or_create_by(object: self, flag: 'permission', data: 'write')
    user.entitlements << write_entitlement if user.entitlements.exclude?(write_entitlement)
    5.times do
      emoji = generate_random_emoji
      emoji_entitlement = Entitlement.find_or_create_by(object: self, flag: 'emoji', data: emoji)
      user.entitlements << emoji_entitlement if user.entitlements.exclude?(emoji_entitlement)
    end
  end

  private

  def generate_random_emoji
    used_emoji = chat.chat_users.map(&:icon).compact
    all_emoji = []
    # rubocop:disable Rails/FindEach
    Emoji.all.each do |e|
      all_emoji << e.raw if !e.nil? && !e.raw.nil? && e.raw.length == 1 && used_emoji.exclude?(e.raw)
    end
    # rubocop:enable Rails/FindEach
    blacklisted_emoji = CardinalSettings::Icons.icon_blacklist
    available_emoji = all_emoji - blacklisted_emoji
    available_emoji.sample
  end

  def generate_icon
    self.icon = generate_random_emoji
  end

  def generate_icon_entitlement
    emoji_entitlement = Entitlement.find_or_create_by(object: self, flag: 'emoji', data: icon)
    user.entitlements << emoji_entitlement if user.entitlements.exclude?(emoji_entitlement)
  end

  def check_icon
    return if skip_check_icon
    return unless icon != icon_was

    blacklisted_icons = CardinalSettings::Icons.icon_blacklist
    user_available_icons = available_icons

    blacklist_bypass = user_available_icons.intersect?(blacklisted_icons)

    return if user_available_icons.include?(icon)
    return if blacklisted_icons.include?(icon) && blacklist_bypass

    errors.add(:icon, 'You are not entitled to this icon.')
  end

  def authorization
    return unless !pseudonym.nil? && pseudonym.user.id != user.id

    errors.add(:pseudonym, 'You are not authorized to do that.')
  end
end
