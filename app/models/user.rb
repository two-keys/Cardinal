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
    super && !delete_at && !unban_at
  end

  def inactive_message
    return unless delete_at || unban_at

    return 'This account is pending for deletion.' if delete_at

    "You are banned for the following: '#{ban_reason}', and your ban lasts until #{unban_at.to_fs(:long_ordinal)}"
  end

  def joined?(chat)
    chats.exists?(id: chat.id)
  end

  def notifications
    notifications = ChatUser.where(user: self, status: %i[unread unanswered ended])
    unread_count = notifications.where(status: :unread).count
    unanswered_count = notifications.where(status: :unanswered).count
    ended_count = notifications.where(status: :ended).count
    { unread: unread_count, unanswered: unanswered_count, ended: ended_count }
  end
end
