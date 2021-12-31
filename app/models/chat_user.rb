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
  validates :icon, uniqueness: { scope: :chat_id }, length: { maximum: 1 }
  
  after_commit :update_chat_status

  def update_chat_status
    broadcast_replace_later_to("user_" + self.user.id.to_s + "_notifications", target: "notifications", partial: 'notifications_frame')
  end

  private
    def generate_icon
      emojis = Emoji.all
      emojis.delete '🐦' # System-only emoji
      self.chat.chat_users.each do |chat_user|
        emojis.delete(chat_user.icon)
      end
      self.icon = emojis.sample.raw
    end
end
