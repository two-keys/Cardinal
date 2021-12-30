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

  validates :user_id, uniqueness: { scope: :chat_id }
end
