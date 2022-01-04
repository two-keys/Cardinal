# frozen_string_literal: true

class ChatUser < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  enum status: {
    ongoing: 0,
    unanswered: 1,
    unread: 2,
    ended: 3,
    ended_viewed: 4
  }

  before_validation :generate_icon, on: :create

  validates :user_id, uniqueness: { scope: :chat_id }
  validates :icon, uniqueness: { scope: :chat_id }, length: { maximum: 70 }

  after_create :broadcast_status_to_chat
  after_destroy :broadcast_status_to_chat
  after_save :broadcast_status_to_user

  def broadcast_status_to_user
    return unless saved_change_to_status?
    notifications = ChatUser.where(user: user, status: %i[unread unanswered ended])
    unread_count = notifications.where(status: :unread).count
    unanswered_count = notifications.where(status: :unanswered).count
    ended_count = notifications.where(status: :ended).count
    notification_counts = { unread: unread_count, unanswered: unanswered_count, ended: ended_count }
    broadcast_update_to("user_#{user.id}_notifications", target: 'notifications',
                                                         partial: 'notifications', locals: { notifications: notification_counts })
  end

  def broadcast_status_to_chat
    broadcast_replace_later_to("chat_#{chat.id}_userlist", target: "chat_#{chat.id}_userlist",
                                                           partial: 'chats/chat_sidebar',
                                                           locals: { locals: { chat: chat } })
  end

  def message_sent
    dynamic_notify unless Rails.env.test?
  end

  def dynamic_notify
    redis = ActionCable.server.pubsub.send(:redis_connection)
    if redis.pubsub('channels', "user_#{user.id}_chat_#{chat.id}").count.zero?
      notify!
    else
      viewed!
    end
  end

  ## This is kind of forced to have high complexity, there's a lot that
  ## goes into determining the user's notification status.
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def viewed!
    return if ended_viewed?

    if ended?
      self.status = 'ended_viewed'
    elsif unread?
      self.status = 'ongoing' if chat.messages.last.user == user || chat.messages.last.user.nil?
      self.status = 'unanswered' if chat.messages.last.user != user
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

  def notify!
    return if ended?
    return if ended_viewed?
    return if chat.messages.count == 1

    self.status = 'unread'
    save!
  end

  private

  def generate_icon
    emojis = Emoji.all
    emojis.delete '🐦' # System-only emoji
    chat.chat_users.each do |chat_user|
      emojis.delete(chat_user.icon)
    end
    self.icon = emojis.sample.raw
  end
end
