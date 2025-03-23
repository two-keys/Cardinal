# frozen_string_literal: true

require 'ruby-progressbar'

class Numeric
  def percent_of(n) # rubocop:disable Naming/MethodParameterName
    (to_f / n.to_f * 100.0).round(2) # rubocop:disable Style/FloatDivision
  end
end

desc 'Migrates data from the Cherp database to Cardinal format'
task cherp_transfer: [:environment] do # rubocop:disable Metrics/BlockLength
  Current.transfer = true
  Devise::Mailer.perform_deliveries = false

  @progressbar = ProgressBar.create
  @progressbar_format = '%a %e |%b>>%i| %P%% %t'

  existing_users = User.all.map(&:id)
  @progressbar.log "Existing Users: #{existing_users.count}"
  @migration_users = Legacy::User.where.not(id: existing_users)
  @migration_users_count = @migration_users.count
  @progressbar.log "Users left to Migrate: #{@migration_users_count}"

  existing_announcements = Announcement.all.map(&:id)
  @progressbar.log "Existing Announcements: #{existing_announcements.count}"
  @migration_announcements = Legacy::Announcement.where.not(id: existing_announcements)
  @migration_announcements_count = @migration_announcements.count
  @progressbar.log "Announcements left to Migrate: #{@migration_announcements_count}"

  existing_characters = Character.all.map(&:id)
  @progressbar.log "Existing Characters: #{existing_characters.count}"
  @migration_characters = Legacy::Character.where.not(id: existing_characters)
  @migration_characters_count = @migration_characters.count
  @progressbar.log "Characters left to Migrate: #{@migration_characters_count}"

  existing_prompts = Prompt.all.map(&:id)
  @progressbar.log "Existing Prompts: #{existing_prompts.count}"
  @migration_prompts = Legacy::Prompt.where.not(id: existing_prompts)
  @migration_prompts_count = @migration_prompts.count
  @progressbar.log "Prompts left to Migrate: #{@migration_prompts_count}"

  existing_chats = Chat.all.map(&:id)
  @progressbar.log "Existing Chats: #{existing_chats.count}"
  @migration_chats = Legacy::Chat.where.not(id: existing_chats).order(id: :desc)
  @migration_chats_count = @migration_chats.count
  @progressbar.log "Chats left to Migrate: #{@migration_chats_count}"

  empty_chats = Chat.where.missing(:chat_users).map(&:id)
  @empty_chats_legacy = Legacy::Chat.where(id: empty_chats).order(id: :desc)
  @empty_chats_count = @empty_chats_legacy.count
  @progressbar.log "Chats needing ChatUser migration: #{@empty_chats_count}"

  existing_messages = Message.all.map(&:id)
  @progressbar.log "Existing Messages: #{existing_messages.count}"
  @migration_messages = Legacy::Message.where.not(id: existing_messages)
  @migration_messages_count = @migration_messages.count
  @progressbar.log "Messages left to Migrate #{@migration_messages_count}"

  existing_alerts = Alert.all.map(&:id)
  @progressbar.log "Existing Alerts: #{existing_alerts.count}"
  @migration_alerts = Legacy::AlertFilter.where.not(id: existing_alerts)
  @migration_alerts_count = @migration_alerts.count
  @progressbar.log "Alerts left to Migrate: #{@migration_alerts_count}"

  @processed_alerts = 0
  def migrate_alert(legacy_alert)
    @processed_alerts += 1
    # @progressbar.log "Migrating Alert #{@processed_alerts} / #{@migration_alerts_count} ( #{@processed_alerts.percent_of(@migration_alerts_count)}% ) - #{legacy_alert.id}" # rubocop:disable Layout/LineLength
    new_alert = Alert.new
    now = Time.zone.now
    new_alert.id = legacy_alert.id
    new_alert.title = legacy_alert.filter
    new_alert.find = legacy_alert.filter
    new_alert.replacement = legacy_alert.replacement
    new_alert.regex = legacy_alert.type == 'regex'
    new_alert.created_at = now
    new_alert.updated_at = now
    new_alert.save
  end

  @processed_users = 0
  def migrate_user(legacy_user)
    @processed_users += 1
    # @progressbar.log "Migrating User #{@processed_users} / #{@migration_users_count} ( #{@processed_users.percent_of(@migration_users_count)}% )- #{legacy_user.user_name}." # rubocop:disable Layout/LineLength
    new_count = User.where('username LIKE :name', name: "#{legacy_user.user_name}%").count
    new_user = User.new
    new_user.password = 'placeholder'
    new_user.password_confirmation = 'placeholder'
    new_user.legacy = true
    new_user.skip_confirmation!
    if new_count.positive?
      @progressbar.log "WARN: Duplicate username #{legacy_user.user_name}, translating to #{legacy_user.user_name}_#{new_count}" # rubocop:disable Layout/LineLength
    end
    new_user.username = new_count.zero? ? legacy_user.user_name : "#{legacy_user.user_name}_#{new_count}"
    new_user.id = legacy_user.id
    new_user.created_at = legacy_user.created
    new_user.verified = legacy_user.verified
    new_user.encrypted_password = legacy_user.password

    result = new_user.save

    if result
      new_user.update!(encrypted_password: legacy_user.password)
    else
      new_user.errors.full_messages.each do |message|
        @progressbar.log message
      end
    end
  end

  @processed_announcements = 0
  def migrate_announcement(legacy_announcement)
    @processed_announcements += 1
    # @progressbar.log "Migrating Announcement #{@processed_announcements} / #{@migration_announcements_count} ( #{@processed_announcements.percent_of(@migration_announcements_count)}% ) - #{legacy_announcement.id}" # rubocop:disable Layout/LineLength
    new_announcement = Announcement.new
    new_announcement.id = legacy_announcement.id
    new_announcement.content = legacy_announcement.announcement_content
    new_announcement.created_at = legacy_announcement.timestamp
    new_announcement.updated_at = legacy_announcement.edited_on
    new_announcement.push = false
    new_announcement.save
  end

  @processed_characters = 0
  def migrate_character(legacy_character)
    @processed_characters += 1
    # @progressbar.log "Migrating Character #{@processed_characters} / #{@migration_characters_count} ( #{@processed_characters.percent_of(@migration_characters_count)}% ) - #{legacy_character.id}." # rubocop:disable Layout/LineLength
    new_character = Character.new
    new_character.id = legacy_character.id
    new_character.created_at = legacy_character.posted
    new_character.updated_at = legacy_character.edited || legacy_character.posted
    new_character.user_id = legacy_character.owner_id
    new_character.name = legacy_character.char_name
    new_character.description = legacy_character.char_description
    new_character.color = legacy_character.colour

    new_character.save(validate: false)
  end

  @processed_prompts = 0
  def migrate_prompt(legacy_prompt)
    @processed_prompts += 1
    # @progressbar.log "Migrating Prompt #{@processed_prompts} / #{@migration_prompts_count} ( #{@processed_prompts.percent_of(@migration_prompts_count)}% ) - #{legacy_prompt.id}." # rubocop:disable Layout/LineLength
    new_prompt = Prompt.new
    new_prompt.id = legacy_prompt.id
    new_prompt.created_at = legacy_prompt.posted
    new_prompt.updated_at = legacy_prompt.edited || legacy_prompt.posted
    new_prompt.bumped_at = legacy_prompt.last_bump
    new_prompt.ooc = legacy_prompt.ooc_notes
    new_prompt.starter = legacy_prompt.starter
    new_prompt.color = legacy_prompt.colour
    new_prompt.user_id = legacy_prompt.owner_id

    new_prompt.save(validate: false)
  end

  @processed_chats = 0
  def migrate_chat(legacy_chat)
    @processed_chats += 1
    new_chat = Chat.new
    existing_prompt = legacy_chat.prompt_id.zero? ? nil : Prompt.find_by(id: legacy_chat.prompt_id)

    # @progressbar.log "Migrating Chat #{@processed_chats} / #{@migration_chats_count} ( #{@processed_chats.percent_of(@migration_chats_count)}% ) - #{legacy_chat.chat_url}" # rubocop:disable Layout/LineLength
    new_chat.id = legacy_chat.id
    new_chat.prompt_id = legacy_chat.prompt_id != 0 && existing_prompt ? legacy_chat.prompt_id : nil
    new_chat.created_at = legacy_chat.created
    new_chat.updated_at = legacy_chat.updated
    new_chat.save
  end

  @processed_chat_users = 0
  @processed_chat_users_chats = 0
  def migrate_chat_users(legacy_chat)
    @processed_chat_users_chats += 1
    new_chat_user = nil
    ActiveRecord::Base.transaction do
      legacy_chat.participants.each do |participant_id|
        @processed_chat_users += 1
        participant_index = legacy_chat.participants.find_index(participant_id)
        participant_status = legacy_chat.chat_status[participant_index]
        new_status = ''
        new_status = 'ongoing' if participant_status == 'answered'
        new_status = 'unread' if participant_status == 'unread'
        new_status = 'unanswered' if participant_status == 'unanswered'
        new_status = 'ongoing' if participant_status.nil?
        new_status = 'ended' if legacy_chat.participants.count == 1
        new_chat_user = ChatUser.new
        # @progressbar.log "Migrating ChatUser #{@processed_chat_users} ( #{@processed_chat_users_chats.percent_of(@migration_chats_count)}% ) - #{legacy_chat.id}|#{participant_id} (#{new_status})." # rubocop:disable Layout/LineLength
        new_chat_user.chat_id = legacy_chat.id
        new_chat_user.user_id = participant_id
        new_chat_user.role = ChatUser.roles[:chat_user]
        new_chat_user.status = new_status
        new_chat_user.save
      end
    end
    migrate_messages(legacy_chat.messages)
    new_chat_user.chat.update(updated_at: new_chat_user.chat.messages.last.created_at)
  end

  @processed_messages = 0
  def migrate_messages(legacy_messages)
    @processed_messages += 1
    legacy_messages.each do |legacy_message|
      @processed_messages += 1
      # @progressbar.log "Migrating Message #{@processed_messages} / #{@migration_messages_count} ( #{@processed_messages.percent_of(@migration_messages_count)}% ) - #{legacy_message.id}." # rubocop:disable Layout/LineLength
      new_message = Message.new
      new_message.id = legacy_message.id
      new_message.chat_id = legacy_message.chat_id
      new_message.user_id = legacy_message.message_sender.zero? ? nil : legacy_message.message_sender
      new_message.content = legacy_message.message_content
      new_message.color = legacy_message.colour
      new_message.created_at = legacy_message.timestamp
      new_message.updated_at = legacy_message.edited_on
      new_message.ooc = legacy_message.message_type == 'ooc'

      begin
        new_message.save
      rescue ActiveRecord::RecordNotUnique
        @progressbar.log "WARN: Message #{new_message.id} already exists. Skipping."
      end
    end
  end

  if @migration_users_count.positive?
    @progressbar.log 'Begin migrating users.'
    @progressbar = ProgressBar.create(title: 'Users', format: @progressbar_format, total: @migration_users_count)
    @migration_users.each do |legacy_user|
      migrate_user(legacy_user)
      @progressbar.increment
    end
    @progressbar.log 'End migrating users.'
  end

  if @migration_announcements_count.positive?
    @progressbar.log 'Begin migrating announcements.'
    @progressbar = ProgressBar.create(title: 'Announcements', format: @progressbar_format,
                                      total: @migration_announcements_count)
    @migration_announcements.each do |legacy_announcement|
      migrate_announcement(legacy_announcement)
      @progressbar.increment
    end
    @progressbar.log 'End migrating announcements.'
  end

  if @migration_characters_count.positive?
    @progressbar.log 'Begin migrating characters.'
    @progressbar = ProgressBar.create(title: 'Characters', format: @progressbar_format,
                                      total: @migration_characters_count)
    @migration_characters.each do |legacy_character|
      migrate_character(legacy_character)
      @progressbar.increment
    end
    @progressbar.log 'End migrating characters.'
  end

  if @migration_prompts_count.positive?
    @progressbar.log 'Begin migrating prompts.'
    @progressbar = ProgressBar.create(title: 'Prompts', format: @progressbar_format, total: @migration_prompts_count)
    @migration_prompts.each do |legacy_prompt|
      migrate_prompt(legacy_prompt)
      @progressbar.increment
    end
    @progressbar.log 'End migrating prompts.'
  end

  if @migration_chats_count.positive?
    @progressbar.log 'Begin migrating chats.'
    @progressbar = ProgressBar.create(title: 'Chats', format: @progressbar_format, total: @migration_chats_count)
    @migration_chats.each do |legacy_chat|
      migrate_chat(legacy_chat)
      @progressbar.increment
    end
    @progressbar.log 'End migrating chats.'

    @progressbar.log 'Begin migrating chat_users.'
    @progressbar = ProgressBar.create(title: 'Chats (ChatUsers)', format: @progressbar_format,
                                      total: @migration_chats_count)
    @migration_chats.each do |legacy_chat|
      migrate_chat_users(legacy_chat)
      @progressbar.increment
    end
    @progressbar.log 'End migrating chat_users'
  end

  if @empty_chats_count.positive?
    @progressbar.log 'Begin migrating chat_users for empty existing.'
    @progressbar = ProgressBar.create(title: 'Chats (Empty)', format: @progressbar_format, total: @empty_chats_count)
    @empty_chats_legacy.each do |legacy_chat|
      migrate_chat_users(legacy_chat)
      @progressbar.increment
    end
    @progressbar.log 'End migrating chat_users for empty existing.'
  end

  if @migration_alerts_count.positive?
    @progressbar.log 'Begin migrating alerts.'
    @progressbar = ProgressBar.create(title: 'Alerts', format: @progressbar_format, total: @migration_alerts_count)
    @migration_alerts.each do |legacy_alert|
      migrate_alert(legacy_alert)
      @progressbar.increment
    end
    @progressbar.log 'End migrating alerts.'
  end

  @progressbar.log 'Begin setting admin accounts.'
  Legacy::User.where.not(account_type: %w[user banned]).find_each do |admin_account|
    account = User.find(admin_account.id)
    account.admin = true
    account.save
  end
  @progressbar.log 'End setting admin accounts.'

  @progressbar.log 'Resetting primary key sequences.'
  ApplicationRecord.connection.tables.each do |t|
    ApplicationRecord.connection.reset_pk_sequence!(t)
  end
  @progressbar.log 'Done resetting primary key sequences.'
end
