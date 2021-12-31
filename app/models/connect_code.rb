# frozen_string_literal: true

class ConnectCode < ApplicationRecord
  require 'securerandom'

  belongs_to :user
  belongs_to :chat

  before_validation :generate_code, on: :create

  validates :remaining_uses, numericality: { only_integer: true, less_than: 10 }

  def use(user)
    if remaining_uses.positive?
      self.remaining_uses -= 1
      self.chat.users << user
      self.chat.messages << Message.new(content: "#{chat.chat_users.find_by(user: user).icon} has joined the chat. #{remaining_uses} uses remaining.")
      self.chat.notify_all_except(user)
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
