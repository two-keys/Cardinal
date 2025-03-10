# frozen_string_literal: true

class ConnectCode < ApplicationRecord
  require 'securerandom'

  belongs_to :user
  belongs_to :chat

  enum :status, {
    unlisted: 0,
    listed: 1
  }

  before_validation :generate_code, on: :create

  validates :remaining_uses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def use(user)
    if remaining_uses.positive?
      self.remaining_uses -= 1
      chat.users << user
      use_message = "#{chat.chat_users.find_by(user:).icon} has joined the chat. #{remaining_uses} uses remaining."
      chat.messages << Message.new(content: use_message)
      save
      true
    else
      false
    end
  end

  def generate_code
    self.code = SecureRandom.alphanumeric(10)
  end
end
