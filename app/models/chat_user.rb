# frozen_string_literal: true

class ChatUser < ApplicationRecord
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

  before_validation :generate_icon, on: :create

  validates :user_id, uniqueness: { scope: :chat_id }
  validates :icon, uniqueness: { scope: :chat_id }, length: { maximum: 70 }, presence: true
  validate :authorization, on: %i[create update]

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

  private

  def generate_icon
    used_emoji = chat.chat_users.map(&:icon).compact
    all_emoji = []
    # rubocop:disable Rails/FindEach
    Emoji.all.each do |e|
      all_emoji << e.raw if !e.nil? && !e.raw.nil? && e.raw.length == 1 && used_emoji.exclude?(e.raw)
    end
    # rubocop:enable Rails/FindEach
    blacklisted_emoji = CardinalSettings::Icons.icon_blacklist
    available_emoji = all_emoji - blacklisted_emoji
    self.icon = available_emoji.sample
  end

  def authorization
    return unless !pseudonym.nil? && pseudonym.user.id != user.id

    errors.add(:pseudonym, 'You are not authorized to do that.')
  end
end
