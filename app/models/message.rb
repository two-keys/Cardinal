# frozen_string_literal: true

class Message < ApplicationRecord
  include Markdownable
  include ActionView::RecordIdentifier

  belongs_to :chat
  belongs_to :user, optional: true

  validates :content, presence: true, length: { minimum: 1, maximum: 10_000 }

  default_scope { order('created_at ASC') }

  after_create_commit :broadcast_to_chat
  after_update_commit :broadcast_to_chat_update

  attribute :current_acting_user_id, :integer

  def broadcast_to_chat
    return nil unless current_acting_user_id

    broadcast_append_later_to(dom_id(self.chat), target: 'messages_container', partial:'messages/message_frame', locals: { locals: { message: self }})
  end

  def broadcast_to_chat_update
    return nil unless current_acting_user_id

    broadcast_replace_later_to(dom_id(self.chat), target: dom_id(self), partial:'messages/message_frame', locals: { locals: { message: self }})
  end

  def markdown
    markdown_concern(content)
  end
end
