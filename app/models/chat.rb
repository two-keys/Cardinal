# frozen_string_literal: true

class Chat < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Reportable
  require 'securerandom'

  belongs_to :prompt, optional: true

  has_many :messages, dependent: :delete_all
  has_many :chat_users, dependent: :delete_all
  has_many :users, through: :chat_users,
                   after_remove: :update_userlist,
                   after_add: :update_userlist
  has_one :connect_code, dependent: :destroy
  has_one :mod_chat, dependent: :destroy

  before_validation :generate_uuid, on: :create
  validates :uuid, presence: true, uniqueness: true

  def search(text)
    Chat.search(id, text)
  end

  def broadcast_status_to_users
    active_notification_users.each do |user|
      broadcast_update_to("user_#{user.id}_notifications", target: 'notifications',
                                                           partial: 'notifications',
                                                           locals: { notifications: user.notifications })
    end
  end

  def update_userlist(_user)
    return if id.nil?

    active_chat_users.each do |user|
      broadcast_replace_later_to("chat_#{id}_user_#{user.id}_userlist",
                                 target: "chat_#{id}_user_#{user.id}_userlist",
                                 partial: 'chats/chat_sidebar',
                                 locals: { locals: { chat_id: id, users_data: all_users_display_data,
                                                     chat_uuid: uuid, user: } })
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
    chat_users.find_by(user:)
  end

  def get_user_display_data(user)
    { icon: chat_users.find_by(user_id: user.id).icon, id: user.id }
  end

  def all_users_display_data
    users.map { |user| { icon: chat_users.find_by(user_id: user.id).icon, id: user.id } }
  end

  def message_sent(message) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if messages.count == 1
    return if message.silent?

    users_to_unread = chat_users.where.not(user: active_chat_users).where(status: %i[ongoing unanswered])
    if mod_chat.present?
      users_to_unread.each do |u|
        u.update(status: :unread)
        u.user.push_subscriptions.each do |s|
          s.push('New Modchat Unread', 'Click to view', url: "/chats/#{uuid}")
        end
      end
      mod_chat.alert_new_message(message)

      case mod_chat.status
      when 'ongoing'
        unless message.user&.admin?
          mod_chat.unanswered!
          mod_chat.alert_status_changed(message)
        end
      when 'unanswered'
        if message.user&.admin? && !message.hidden?
          mod_chat.ongoing!
          mod_chat.alert_status_changed(message.user)
        end
      when 'resolved'
        if message.user&.admin?
          mod_chat.ongoing!
        else
          mod_chat.unanswered! unless message.user.nil?
        end
        mod_chat.alert_status_changed(message.user)
      end
    else
      users_to_unread.each do |u|
        u.update(status: :unread)
        u.user.push_subscriptions.each do |s|
          s.push('New Unread', 'Click to view', url: "/chats/#{uuid}")
        end
      end
    end

    users_to_unanswered = chat_users.where(user: active_chat_users - [message.user])
    users_to_unanswered.each { |u| u.update(status: :unanswered) }

    users_to_ongoing = chat_users.where(user: message.user)
    users_to_ongoing.each { |u| u.update(status: :ongoing) unless u.ended? || u.ended_viewed? }

    active_chat_users.each(&:reload)
    broadcast_status_to_users
  end

  def viewed!(user)
    chat_user = chat_users.find_by(user:)
    return unless chat_user && !chat_user.ended_viewed?

    chat_users.find_by(user:).viewed!
  end

  def active_chat_users
    active_channels("user_*_chat_#{id}")
  end

  def active_notification_users
    active_channels('user_*_notifications')
  end

  # Checks the redis database for channels that're currently in use by a user
  # This means that they are online.
  def active_channels(channel_string)
    ## Tests do not support this.
    return [] if Rails.env.test?

    online_users = []

    redis = ActionCable.server.pubsub.send(:redis_connection)
    redis.pubsub('channels', channel_string).each do |channel|
      int_user_id = channel.split('_').second.to_i if channel.present?
      user = User.find_by(id: int_user_id) unless int_user_id.nil?
      online_users << user unless user.nil?
    end

    online_users
  end

  def self.search(id, text)
    results = PgSearch.multisearch(text).where(chat_id: id).map(&:searchable_id)
    Message.where(id: results)
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
