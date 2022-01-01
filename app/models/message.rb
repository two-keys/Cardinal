# frozen_string_literal: true

class Message < ApplicationRecord
  include Markdownable

  belongs_to :chat
  belongs_to :user, optional: true

  validates :content, presence: true, length: { maximum: 50_000 }
  validates :icon, presence: true, length: { maximum: 70 }
  validate :authorization, on: :create
  validate :authorization, on: :update

  before_validation :set_icon, on: :create

  default_scope { order('created_at ASC') }

  after_create :update_timestamp
  after_create_commit :set_unreads
  after_create_commit :broadcast_to_chat
  after_update_commit :broadcast_to_chat_update

  def update_timestamp
    Chat.record_timestamps = false
    chat.updated_at = Time.zone.now
    Chat.record_timestamps = true
    chat.save!
  end

  def set_unreads
    # Rails tests do NOT support this
    return if Rails.env.test?

    redis = ActionCable.server.pubsub.send(:redis_connection)
    chat.chat_users.each do |chat_user|
      chat_user.unread! if redis.pubsub('channels', "user_#{chat_user.id}_chat_#{chat.id}").empty?
    end
  end

  def broadcast_to_chat
    chat.chat_users.each do |chat_user|
      broadcast_append_later_to("user_#{chat_user.user.id}_chat_#{chat_user.chat.id}",
                                target: 'messages_container',
                                partial: 'messages/message_frame', locals: { locals: { message: self } })
    end
  end

  def broadcast_to_chat_update
    chat.chat_users.each do |chat_user|
      broadcast_replace_later_to("user_#{chat_user.user.id}_chat_#{chat_user.chat.id}",
                                 target: "message_#{id}",
                                 partial: 'messages/message_frame', locals: { locals: { message: self } })
    end
  end

  def markdown
    markdown_concern(content)
  end

  def type
    if user_id.nil?
      'system'
    else
      'user'
    end
  end

  private

  def set_icon
    self.icon = if user_id.nil?
                  '🐦'
                else
                  user.chat_users.find_by(chat_id: chat_id).icon
                end
  end

  def authorization
    return if user_id.nil?
    return unless chat.users.include?(user)
    return unless user_id_changed? || (chat_id_changed? && persisted?)

    errors.add('You are not authorized to do that.')
  end
end
