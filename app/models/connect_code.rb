# frozen_string_literal: true

class ConnectCode < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  validates :remaining_uses, numericality: { only_integer: true, less_than_or_equal_to: 10 }

  def use(user)
    if remaining_uses.positive?
      self.remaining_uses -= 1
      chat.users << user
      save
      true
    else
      false
    end
  end
end
