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

  scope :display, -> { order('created_at DESC') }

  after_create :update_timestamp
  after_create_commit :update_chat
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update

  def update_timestamp
    return if chat.frozen?

    Chat.record_timestamps = false
    chat.updated_at = Time.zone.now
    Chat.record_timestamps = true
    chat.save!
  end

  def update_chat
    chat.message_sent
  end

  def broadcast_create
    chat.active_chat_users.each do |active_user|
      if chat.messages.count > 20
        broadcast_remove_to("user_#{active_user.id}_chat_#{chat.id}", target: "message_#{chat.messages[-21].id}")
      end
      broadcast_append_later_to("user_#{active_user.id}_chat_#{chat.id}",
                                target: 'messages_container',
                                partial: 'messages/message_frame', locals: { locals: { message: self } })
    end
  end

  def broadcast_update
    chat.active_chat_users.each do |active_user|
      broadcast_replace_later_to("user_#{active_user.id}_chat_#{chat.id}",
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
                  CardinalSettings::Icons.system_icon
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
