# frozen_string_literal: true

class Chat < ApplicationRecord
  require 'securerandom'

  has_many :messages, dependent: :delete_all
  has_many :chat_users, dependent: :delete_all
  has_many :users, through: :chat_users,
                   after_remove: :update_userlist,
                   after_add: :update_userlist
  has_one :connect_code, dependent: :destroy

  before_validation :generate_uuid, on: :create
  validates :uuid, presence: true, uniqueness: true

  def update_userlist(_user)
    return if id.nil?

    users.each do |user|
      logger.debug "Updating userlist for user #{user.id} on chat #{id}"
      broadcast_replace_later_to("chat_#{id}_user_#{user.id}_userlist",
                                 target: "chat_#{id}_user_#{user.id}_userlist",
                                 partial: 'chats/chat_sidebar',
                                 locals: { locals: { chat_id: id, users_data: all_users_display_data,
                                                     chat_uuid: uuid, user: user } })
    end
    reenable_chat if users.count > 1
  end

  def reenable_chat
    chat_users.each do |chat_user|
      if chat_user.status == 'ended' || chat_user.status == 'ended_viewed'
        chat_user.status = 'unread'
        chat_user.save
      end
    end
  end

  def get_user_info(user)
    chat_users.find_by(user: user)
  end

  def get_user_display_data(user)
    { icon: chat_users.find_by(user_id: user.id).icon, id: user.id }
  end

  def all_users_display_data
    users_data = []
    users.each do |user|
      users_data << { icon: chat_users.find_by(user_id: user.id).icon, id: user.id }
    end
    users_data
  end

  def message_sent
    chat_users.each(&:message_sent)
  end

  def viewed!(user)
    chat_users.find_by(user: user).viewed!
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
