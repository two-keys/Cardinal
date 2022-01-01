# frozen_string_literal: true

class Message < ApplicationRecord
  include Markdownable

  belongs_to :chat
  belongs_to :user, optional: true

  validates :content, presence: true, length: { maximum: 50_000 }

  before_validation :set_icon, on: :create

  default_scope { order('created_at ASC') }

  after_create :update_timestamp
  after_create_commit :set_unreads
  after_create_commit :broadcast_to_chat
  after_update_commit :broadcast_to_chat_update

  def update_timestamp
    Chat.record_timestamps = false
    chat.updated_at = Time.now
    Chat.record_timestamps = true
    chat.save!
  end

  def set_unreads
    redis = ActionCable.server.pubsub.send(:redis_connection)
    for chat_user in self.chat.chat_users do
      if redis.pubsub("channels", "user_#{chat_user.id}_chat_#{self.chat.id}").empty?
        chat_user.unread!
      end
    end
  end

  def broadcast_to_chat
    for chat_user in self.chat.chat_users do
      broadcast_append_later_to("user_#{chat_user.user.id}_chat_#{chat_user.chat.id}", target: 'messages_container', partial:'messages/message_frame', locals: { locals: { message: self }})
    end
  end

  def broadcast_to_chat_update
    for chat_user in self.chat.chat_users do
      broadcast_replace_later_to("user_#{chat_user.user.id}_chat_#{chat_user.chat.id}", target: "message_#{id}", partial:'messages/message_frame', locals: { locals: { message: self }})
    end
  end

  def markdown
    markdown_concern(content)
  end

  def type
    if self.user_id.nil?
      'system'
    else
      'user'
    end
  end

  private
    def set_icon
      if self.user_id.nil?
        self.icon = '🐦'
      else
        self.icon = self.user.chat_users.find_by(chat_id: self.chat_id).icon
      end
    end
end
