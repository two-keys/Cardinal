# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  validates :username, presence: true, uniqueness: true

  has_many :chats_users, dependent: :delete_all
  has_many :chats, through: :chats_users
  has_many :messages
  has_many :connect_codes, dependent: :destroy

  def active_for_authentication?
    super && !delete_at
  end
end
