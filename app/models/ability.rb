# frozen_string_literal: true

# rubocop:disable Style/HashSyntax
class Ability
  include CanCan::Ability

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
    can :create, PromptTag, prompt: { user: }
    can :create, Prompt

    ## Reading
    can :read, Message do |message|
      user.chats.include?(message.chat) || user == message.user
    end
    can :read, Chat do |chat|
      chat.users.include?(user)
    end
    can :read, ConnectCode, user: user
    can :read, Filter, user: user
    can :read, PromptTag, prompt: { user: }
    can :read, Prompt, status: 'posted'
    can :read, Prompt, user: user
    can :read, Tag, enabled: true
    can :read, Ticket, user: user
    can :read, User, user: user

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
    can :update, PromptTag, prompt: { user: }
    can :update, Prompt, user: user
    can :update, User, user: user

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
    can :destroy, PromptTag, prompt: { user: }
    can :destroy, Prompt, user: user
    can :destroy, Ticket, user: user
    can :destroy, User, user: user

    ## Non-CRUD Actions
    can :chat_kick, Chat do |chat|
      ChatUser.find_by(chat:, user:).chat_admin?
    end
    can :forceongoing, Chat do |chat|
      chat.users.include?(user)
    end
    can :consume, ConnectCode
    can :bump, Prompt, user: user
    can :update_tags, Prompt, user: user
    can :answer, Prompt
    cannot :answer, Prompt, user: user
    can :search, Prompt
    can :generate_search, Prompt
    can :autocomplete, Tag

    unless user.active_for_authentication?
      # Things which banned users cannot do

      cannot :create, :all
      cannot :update, :all
      cannot :destroy, :all

      ## Non-CRUD Actions
      cannot :bump, Prompt
      cannot :update_tags, Prompt
      cannot :answer, Prompt
    end

    return unless user.admin?

    # Things which admins can do

    can :manage, :all
    can :view_users, :all
  end
end
# rubocop:enable Style/HashSyntax
