# frozen_string_literal: true

class Message < ApplicationRecord
  include Markdownable
  include ActionView::RecordIdentifier

  belongs_to :chat
  belongs_to :user, optional: true

  validates :content, presence: true, length: { minimum: 1, maximum: 50_000 }

  before_validation :set_icon, on: :create

  default_scope { order('created_at ASC') }

  after_create_commit :broadcast_to_chat
  after_update_commit :broadcast_to_chat_update

  def broadcast_to_chat
    broadcast_append_later_to(dom_id(self.chat), target: 'messages_container', partial:'messages/message_frame', locals: { locals: { message: self }})
  end

  def broadcast_to_chat_update
    broadcast_replace_later_to(dom_id(self.chat), target: dom_id(self), partial:'messages/message_frame', locals: { locals: { message: self }})
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
