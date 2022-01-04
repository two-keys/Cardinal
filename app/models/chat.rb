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

  def viewed(user)
    chat_info = chat_users.find_by(user: user)

    return if chat_info.ongoing?
    
    if messages.count == 1
      chat_info.ongoing! 
      return
    end
    if messages.first.user != user && messages.first.user != nil
      chat_info.unanswered! 
      return
    end
    if chat_info.ended?
      chat_info.ended_viewed!
      return
    end

    chat_info.ongoing!
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
