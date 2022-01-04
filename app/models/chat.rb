# frozen_string_literal: true

class Chat < ApplicationRecord
  require 'securerandom'

  has_many :messages, dependent: :delete_all
  has_many :chat_users, dependent: :delete_all
  has_many :users, through: :chat_users
  has_one :connect_code, dependent: :destroy

  before_validation :generate_uuid, on: :create
  validates :uuid, presence: true, uniqueness: true

  def get_user_info(user)
    chat_users.find_by(user: user)
  end

  def message_sent(message)
    chat_users.each do |chat_user|
      chat_user.message_sent(message)
    end
  end

  def viewed!(user)
    chat_users.find_by(user: user).viewed!
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
