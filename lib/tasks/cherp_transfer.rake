# frozen_string_literal: true

require 'ruby-progressbar'

class Numeric
  def percent_of(n) # rubocop:disable Naming/MethodParameterName
    (to_f / n.to_f * 100.0).round(2)
  end
end

desc 'Migrates data from the Cherp database to Cardinal format'
task cherp_transfer: [:environment] do # rubocop:disable Metrics/BlockLength
  Current.transfer = true
  Devise::Mailer.perform_deliveries = false

  # used to avoid instantiating every legacy record
  @batch_size = 1000

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

  acceptable_types = %w[fandom character gender characteristic]
  existing_tags = Tag.where(tag_type: acceptable_types)
                     .distinct
                     .pluck(Arel.sql('
                      (CASE polarity
                        WHEN \'seeking\' THEN tag_type || \'_wanted\'
                        ELSE tag_type
                        END || \':\' || lower)
                      '))
  @progressbar.log "Existing Tags: #{existing_tags.count}"
  @migration_tags = Legacy::Tag.where(type: acceptable_types + acceptable_types.map { |tg| "#{tg}_wanted" })
  if existing_tags.count.positive?
    @migration_tags = @migration_tags.where.not(
      '(type || \':\'|| lowercased) IN (?)', existing_tags
    )
  end
  @migration_tags_count = @migration_tags.count
  @progressbar.log "Tags left to Migrate: #{@migration_tags_count}"

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

  existing_ip_bans = IpBan.all.map(&:id)
  @progressbar.log "Existing IP Bans: #{existing_ip_bans.count}"
  @migration_ip_bans = Legacy::IpBan.where.not(id: existing_ip_bans)
  @migration_ip_bans_count = @migration_ip_bans.count
  @progressbar.log "IP Bans left to Migrate: #{@migration_ip_bans_count}"

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

  @processed_ip_bans = 0
  def migrate_ip_ban(legacy_ip_ban)
    @processed_ip_bans += 1
    new_ip_ban = IpBan.new
    now = Time.zone.now
    new_ip_ban.id = legacy_ip_ban.id
    new_ip_ban.context = legacy_ip_ban.reason
    new_ip_ban.addr = legacy_ip_ban.ip_address
    new_ip_ban.created_at = now
    new_ip_ban.updated_at = now
    new_ip_ban.save
  end

  @processed_users = 0
  def migrate_user(legacy_user)
    @processed_users += 1
    # @progressbar.log "Migrating User #{@processed_users} / #{@migration_users_count} ( #{@processed_users.percent_of(@migration_users_count)}% )- #{legacy_user.user_name}." # rubocop:disable Layout/LineLength
    new_user = User.new
    new_user.password = 'placeholder'
    new_user.password_confirmation = 'placeholder'
    new_user.legacy = true
    new_user.skip_confirmation!
    new_user.username = legacy_user.user_name
    new_user.id = legacy_user.id
    new_user.created_at = legacy_user.created
    new_user.verified = legacy_user.verified
    new_user.unban_at = legacy_user.unban_date || 9000.years.from_now if legacy_user.account_type == 'banned'
    new_user.ban_reason = legacy_user.ban_reason if legacy_user.account_type == 'banned'
    new_user.encrypted_password = legacy_user.password

    @retries = 0

    loop do
      result = new_user.save

      if result
        new_user.update!(encrypted_password: legacy_user.password)
        break
      else
        @retries += 1
        new_user.username = "#{legacy_user.user_name}_#{@retries}"
        @progressbar.log "WARN: Duplicate username, attempting #{new_user.username}"
      end
      if @retries >= 50
        @progressbar.log "WARN: Attempted to migrate user #{@retries} times. Skipping."
        break
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

  def get_polarity(tag_type)
    has_wanted = tag_type.include?('wanted')

    polarity = nil

    if has_wanted
      polarity = 'seeking'
    else
      polarity_key = {
        fandom: 'playing',
        character: 'playing',
        gender: 'playing',
        characteristic: 'playing'
      }

      polarity = polarity_key[tag_type.to_sym]
    end

    polarity
  end

  def get_type(tag_type)
    new_type = tag_type

    new_type.slice!('_wanted') if tag_type.include?('_wanted')

    new_type
  end

  @processed_tags = 0
  def migrate_tag(legacy_tag) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    @processed_tags += 1
    if legacy_tag.name.blank?
      @progressbar.log "WARN: Legacy::Tag #{legacy_tag.id} is blank. Skipping."
      return
    end
    nt_polarity = get_polarity(legacy_tag.type)
    if nt_polarity
      new_tag = Tag.find_or_create_with_downcase(
        polarity: nt_polarity,
        tag_type: get_type(legacy_tag.type),
        name: legacy_tag.name # lowercase is automatically handled
      )

      skipped_synonym = legacy_tag.synonym.nil? || (legacy_tag.id == legacy_tag.synonym.id)
      unless skipped_synonym
        legacy_synonym = legacy_tag.synonym

        ns_polarity = get_polarity(legacy_synonym.type)
        if legacy_tag.synonym.lowercased == 'nullify tag'
          new_tag.enabled = false

          full_name = legacy_tag.type + legacy_tag.name
          @progressbar.log "WARN: Synonym is nullify tag, disabling #{full_name}"

          skipped_synonym = true
        elsif ns_polarity
          # synonym chains are automatically crunched
          new_synonym = Tag.find_or_create_with_downcase(
            polarity: ns_polarity,
            tag_type: get_type(legacy_synonym.type),
            name: legacy_synonym.name # lowercase is automatically handled
          )

          new_tag.synonym = new_synonym
        else
          full_name = legacy_synonym.type + legacy_synonym.name
          @progressbar.log "WARN: Synonym type #{legacy_synonym.type} does not map to polarity, skipping #{full_name}"

          skipped_synonym = true
        end
      end

      # ancestry processing
      if skipped_synonym && !(legacy_tag.parent.nil? || legacy_tag.id == legacy_tag.parent.id)
        legacy_parent = legacy_tag.parent

        np_polarity = get_polarity(legacy_parent.type)
        if np_polarity
          new_parent = Tag.find_or_create_with_downcase(
            polarity: np_polarity,
            tag_type: get_type(legacy_parent.type),
            name: legacy_parent.name # lowercase is automatically handled
          )

          new_tag.parent = new_parent
        else
          full_name = legacy_parent.type + legacy_parent.name
          @progressbar.log "WARN: Parent type #{legacy_parent.type} does not map to polarity, skipping #{full_name}"
        end
      end

      new_tag.save
    else
      @progressbar.log "WARN: Tag type #{legacy_tag.type} does not map to polarity, skipping"
    end
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
  end

  @processed_messages = 0
  def migrate_messages(legacy_messages, progressbar)
    message_array = []
    legacy_messages.find_each(batch_size: @batch_size) do |legacy_message|
      @processed_messages += 1
      # @progressbar.log "Migrating Message #{@processed_messages} / #{@migration_messages_count} ( #{@processed_messages.percent_of(@migration_messages_count)}% ) - #{legacy_message.id}." # rubocop:disable Layout/LineLength
      new_message = {}
      new_message[:id] = legacy_message.id
      new_message[:chat_id] = legacy_message.chat_id
      new_message[:user_id] = legacy_message.message_type == 'system' ? nil : legacy_message.message_sender
      new_message[:content] = legacy_message.message_content
      new_message[:color] = legacy_message.colour
      new_message[:created_at] = legacy_message.timestamp
      new_message[:updated_at] = legacy_message.edited_on
      new_message[:ooc] = legacy_message.message_type == 'ooc'

      message_array << new_message
      progressbar.increment
    end

    chunked_messages_array = message_array.each_slice(@batch_size).to_a
    progressbar = ProgressBar.create(title: "Message (insert_all #{@batch_size})", format: @progressbar_format,
                                     total: chunked_messages_array.count)
    chunked_messages_array.each do |chunk|
      Message.insert_all(chunk) # rubocop:disable Rails/SkipsModelValidations
      progressbar.increment
    end
  end

  if @migration_ip_bans_count.positive?
    @progressbar.log 'Begin migrating IP bans.'
    @progressbar = ProgressBar.create(title: 'IP Bans', format: @progressbar_format, total: @migration_ip_bans_count)
    @migration_ip_bans.find_each(batch_size: @batch_size) do |legacy_ip_ban|
      migrate_ip_ban(legacy_ip_ban)
      @progressbar.increment
    end
    @progressbar.log 'End migrating IP bans.'
  end

  if @migration_users_count.positive?
    @progressbar.log 'Begin migrating users.'
    @progressbar = ProgressBar.create(title: 'Users', format: @progressbar_format, total: @migration_users_count)
    @migration_users.find_each(batch_size: @batch_size) do |legacy_user|
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
    @migration_characters.find_each(batch_size: @batch_size) do |legacy_character|
      migrate_character(legacy_character)
      @progressbar.increment
    end
    @progressbar.log 'End migrating characters.'
  end

  if @migration_prompts_count.positive?
    @progressbar.log 'Begin migrating prompts.'
    @progressbar = ProgressBar.create(title: 'Prompts', format: @progressbar_format, total: @migration_prompts_count)
    @migration_prompts.find_each(batch_size: @batch_size) do |legacy_prompt|
      migrate_prompt(legacy_prompt)
      @progressbar.increment
    end
    @progressbar.log 'End migrating prompts.'
  end

  if @migration_tags_count.positive?
    @progressbar.log 'Begin migrating tags.'
    @progressbar = ProgressBar.create(title: 'Tags', format: @progressbar_format, total: @migration_tags_count)
    @migration_tags.find_each(batch_size: @batch_size) do |legacy_tag|
      migrate_tag(legacy_tag)
      @progressbar.increment
    end
    @progressbar.log 'End migrating tags.'
  end

  if @migration_chats_count.positive?
    @progressbar.log 'Begin migrating chats.'
    @progressbar = ProgressBar.create(title: 'Chats', format: @progressbar_format, total: @migration_chats_count)
    @migration_chats.find_each(batch_size: @batch_size) do |legacy_chat|
      migrate_chat(legacy_chat)
      @progressbar.increment
    end
    @progressbar.log 'End migrating chats.'
  end

  if @empty_chats_count.positive?
    @progressbar.log 'Begin migrating chat_users for empty existing.'
    @progressbar = ProgressBar.create(title: 'Chats (Empty)', format: @progressbar_format, total: @empty_chats_count)
    @empty_chats_legacy.find_each(batch_size: @batch_size) do |legacy_chat|
      migrate_chat_users(legacy_chat)
      @progressbar.increment
    end
    @progressbar.log 'End migrating chat_users for empty existing.'
  end

  if @migration_messages_count.positive?
    @progressbar.log 'Begin migrating messages.'
    @progressbar = ProgressBar.create(title: 'Messages', format: @progressbar_format, total: @migration_messages_count)
    migrate_messages(@migration_messages, @progressbar)
    @progressbar.log 'End migrating messages.'
  end

  @progressbar.log 'Setting updated_at for chat_users'
  chats = ChatUser.where('
    EXISTS(
      SELECT id
      FROM messages
      WHERE messages.chat_id = chats.id
    )
  ')
  chats_count = chats.count
  @progressbar = ProgressBar.create(title: 'ChatUsers (updated_at)', format: @progressbar_format,
                                    total: chats_count)
  # rubocop:disable Rails/SkipsModelValidations
  chats.update_all('
    updated_at = COALESCE(
      (SELECT MAX(created_at)
        FROM messages
        WHERE messages.chat_id = chats.id
      ), updated_at
    )
  ')
  # rubocop:enable Rails/SkipsModelValidations
  @progressbar.log 'End setting updated_at for chat_users'

  @progressbar.log 'Set Message Icons'
  null_icons = Message.where(icon: nil)
  @progressbar = ProgressBar.create(title: 'Message Icons', format: @progressbar_format, total: null_icons.count)
  # rubocop:disable Rails/SkipsModelValidations
  null_icons.update_all('
    icon = CASE
      WHEN messages.user_id IS NULL
        THEN \'bird\'
      ELSE COALESCE(
        (
          SELECT cus.icon
          FROM chat_users cus
          WHERE cus.chat_id = messages.chat_id
            AND cus.user_id = messages.user_id
        ), \'bird\')
      END
  ')
  # rubocop:enable Rails/SkipsModelValidations
  @progressbar.log 'End Set Message Icons'

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
