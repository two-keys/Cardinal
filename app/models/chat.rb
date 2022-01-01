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

  def set_viewed(user)
    chat_info = chat_users.find_by(user: user)
    if messages.last.user != user && chat_info.status == 'unread'
      chat_info.unanswered!
      return
    end
    chat_info.ongoing! if chat_info.status == 'ended'
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end

end
