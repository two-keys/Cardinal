# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class Ability
  include CanCan::Ability

  ## This is kind of forced to have high complexity
  ## and high class length, there's a lot that
  ## goes into determining authorization
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def initialize(user)
    # Things which require no login

    can :read, Announcement
    can :create, User

    return if user.blank?

    # Things which require a login

    ## Creating
    cannot :create, User # Logged in users can't make new users
    can :create, Message do |message|
      user.chats.include?(message.chat) && user == message.user
    end
    can :create, Chat
    can :create, ConnectCode
    can :create, Filter
    can :create, ObjectTag, object: { user: }
    can :create, Pseudonym
    can :create, Prompt
    can :create, Character
    can :create, Report do |report|
      user_valid = report.reporter = user
      reportee_valid = !report.reportee.nil?

      # Special case for Message
      # Prevent reporting in chats you are not in
      user_valid = user.chats.include?(report.reportable.chat) if report.reportable_type == 'Message'
      user_valid && reportee_valid
    end
    can :create, Theme
    can :create, PushSubscription

    ## Reading
    can :read, Message do |message|
      user.chats.include?(message.chat) || user == message.user
    end
    can :read, Chat do |chat|
      chat.users.include?(user)
    end
    can :read, ConnectCode, user: user
    can :read, Filter, user: user
    can :read, ObjectTag, object: { user: }
    can :read, Pseudonym, status: 'posted'
    can :read, Pseudonym, user: user
    can :read, Prompt, status: 'posted'
    can :read, Prompt, user: user
    can :read, Character, status: 'posted'
    can :read, Character, user: user
    can :read, Tag, enabled: true
    can :read, Ticket, user: user
    can :read, User, user: user
    can :read, Report, reporter: user
    can :read, Theme, user: user
    can :read, Theme, public: true
    can :read, Theme, system: true

    ## Updating
    can :update, Message do |message|
      user.chats.include?(message.chat) && user == message.user
    end
    can :update, Chat do |chat|
      chat.users.include?(user)
    end
    can :update, ConnectCode do |connect_code|
      ChatUser.exists?(
        chat: connect_code.chat, user:, role: [ChatUser.roles[:chat_admin]]
      )
    end
    can :update, Filter, user: user
    can :update, ObjectTag, object: { user: }
    can :update, Pseudonym, user: user
    can :update, Prompt, user: user
    can :update, Character, user: user
    can :update, User, user: user
    can :update, Theme, user: user

    ## Destroying
    can :destroy, Chat do |chat|
      chat.users.include?(user)
    end
    can :destroy, ConnectCode do |connect_code|
      ChatUser.exists?(
        chat: connect_code.chat, user:, role: [ChatUser.roles[:chat_admin]]
      )
    end
    can :destroy, Filter, user: user
    can :destroy, ObjectTag, object: { user: }
    can :destroy, Pseudonym, user: user
    can :destroy, Prompt, user: user
    can :destroy, Character, user: user
    can :destroy, Ticket do |ticket|
      ticket.user == user && ticket.destroyable?
    end
    can :destroy, User, user: user
    can :destroy, Theme, user: user
    can :destroy, PushSubscription, user: user

    ## Non-CRUD Actions
    can :chat_kick, Chat do |chat|
      ChatUser.find_by(chat:, user:).chat_admin?
    end
    can :forceongoing, Chat do |chat|
      chat.users.include?(user)
    end
    can :search, Chat do |chat|
      chat.users.include?(user)
    end
    can :notifications, Chat
    can :consume, ConnectCode
    can :bump, Prompt, user: user
    can :update_tags, Prompt, user: user
    can :update_tags, Character, user: user
    can :answer, Prompt
    cannot :answer, Prompt, user: user
    can :search, Prompt
    can :search, Character
    can :generate_search, Prompt
    can :generate_search, Character
    can :autocomplete, Tag
    can :lucky_dip, Prompt
    can :history, Prompt, user: user
    can :restore, Prompt, user: user
    can :history, Message, user: user
    can :restore, Message, user: user
    can :history, Character, user: user
    can :restore, Character, user: user
    can :hide, Tag
    can :apply, Theme, user: user
    can :apply, Theme, public: true
    can :apply, Theme, system: true
    can :unapply, Theme

    unless user.active_for_authentication?
      # Things which banned users cannot do

      cannot :create, :all
      cannot :update, :all
      cannot :destroy, :all

      ## Non-CRUD Actions
      cannot :bump, Prompt
      cannot :update_tags, Prompt
      cannot :update_tags, Character
      cannot :answer, Prompt
      cannot :restore, :all
    end

    return unless user.admin?

    # Things which admins can do

    can :manage, :all
    can :history, :all
    can :restore, :all
    can :view_users, :all
    can :view_sensitive, :all
    can :apply, Theme
    cannot :hide, :all
    can :hide, Tag
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
# rubocop:enable Metrics/ClassLength
