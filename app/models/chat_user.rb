# frozen_string_literal: true

class ChatUser < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  enum status: {
    ongoing: 0,
    unanswered: 1,
    unread: 2,
    ended: 3
  }

  before_validation :generate_icon, on: :create

  validates :user_id, uniqueness: { scope: :chat_id }
  validates :icon, uniqueness: { scope: :chat_id }, length: { maximum: 70 }

  after_update_commit :broadcast_status

  def broadcast_status
    # Rails tests do NOT support this
    return if Rails.env.test?

    redis = ActionCable.server.pubsub.send(:redis_connection)

    return unless redis.pubsub('channels', "user_#{user.id}_chat_#{chat.id}").empty?

    broadcast_update_to("user_#{user.id}_notifications", target: 'notifications',
                                                         partial: 'notifications_frame')
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
