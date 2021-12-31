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

  def notify_all
    chat_users.each do |chat_user|
      chat_user.unread!
    end
  end

  def notify_all_except(user)
    chat_users.each do |chat_user|
      chat_user.unread! unless chat_user.user == user
    end
  end

  def set_viewed(user)
    chat_info = chat_users.find_by(user: user)
    if chat_info.unread? && self.messages.last.user != user && !self.messages.last.user.nil?
      chat_info.unanswered!
    else
      chat_info.ongoing!
    end
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end

end
