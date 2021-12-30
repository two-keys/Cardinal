# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  validates :username, presence: true, uniqueness: true

  has_many :chat_users, dependent: :delete_all
  has_many :chats, through: :chat_users
  has_many :messages, dependent: :delete_all
  has_many :connect_codes, dependent: :destroy

  def active_for_authentication?
    super && !delete_at
  end

  def has_joined?(chat)
    chats.where(id: chat.id).exists?
  end
end
