# frozen_string_literal: true

module DiscordHelper # rubocop:disable Metrics/ModuleLength
  include Rails.application.routes.url_helpers

  def send_discord_report(report)
    return if Rails.env.test?

    Discord.webhook_client.execute do |builder|
      builder.add_embed do |embed|
        embed.colour = 0xea6353
        embed.timestamp = Time.zone.now

        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: 'Report', icon_url: 'https://cdn.discordapp.com/embed/avatars/0.png')

        embed.add_field(name: 'Reporter',
                        value: "[#{report.reporter.username}](#{edit_admin_user_url(report.reporter)})", inline: true)
        embed.add_field(name: 'Reportee',
                        value: "[#{report.reportee.username}](#{edit_admin_user_url(report.reportee)})", inline: true)
        embed.add_field(name: 'Rules', value: report.rules.to_s, inline: true)
        embed.add_field(name: 'Context', value: report.context)
        embed.add_field(name: 'Reported Content', value: "[#{report.reportable_type}](#{url_for([:admin, report])})")
      end
    end
  end

  def send_discord_resolved_report(report)
    return if Rails.env.test?

    Discord.webhook_client.execute do |builder|
      builder.add_embed do |embed|
        embed.colour = 0xfba703
        embed.timestamp = Time.zone.now

        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: 'Report Resolved', icon_url: 'https://cdn.discordapp.com/embed/avatars/0.png')

        embed.add_field(name: 'Reporter',
                        value: "[#{report.reporter.username}](#{edit_admin_user_url(report.reporter)})", inline: true)
        embed.add_field(name: 'Reportee',
                        value: "[#{report.reportee.username}](#{edit_admin_user_url(report.reportee)})", inline: true)
        embed.add_field(name: 'Rules', value: report.rules.to_s, inline: true)
        embed.add_field(name: 'Reported Content', value: "[#{report.reportable_type}](#{url_for([:admin, report])})")
        # rubocop:disable Layout/LineLength
        embed.add_field(name: 'Handled By',
                        value: "[#{report.handled_by.username}](#{edit_admin_user_url(report.handled_by)})", inline: true)
        # rubocop:enable Layout/LineLength
      end
    end
  end

  def send_discord_alert(alertable, alerts)
    return if Rails.env.test?

    Discord.webhook_client.execute do |builder|
      builder.add_embed do |embed|
        embed.colour = 0xfba703
        embed.timestamp = Time.zone.now

        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: 'Alert', icon_url: 'https://cdn.discordapp.com/embed/avatars/0.png')

        embed.add_field(name: 'Alerts',
                        value: alerts.map { |alert| "`#{alert}`" }.join(', '), inline: false)
        embed.add_field(name: 'Offender',
                        value: "[#{alertable.user.username}](#{edit_admin_user_url(alertable.user)})", inline: true)

        # Special case for Messages
        if alertable.is_a?(Message)
          embed.add_field(name: 'Alerted Content',
                          value: "[#{alertable.class}](#{chat_url(alertable.chat.uuid)})", inline: true)
        else
          embed.add_field(name: 'Alerted Content',
                          value: "[#{alertable.class}](#{url_for(alertable)})", inline: true)
        end

        alertable.alertable_fields.each do |field|
          value = alertable.send(field).to_s.truncate(200, omission: '...')
          embed.add_field(name: field.to_s.humanize, value: value, inline: false)
        end
      end
    end
  end

  def send_discord_new_modchat(modchat)
    return if Rails.env.test?

    Discord.webhook_client.execute do |builder|
      builder.add_embed do |embed|
        embed.color = 0x00FFFF
        embed.timestamp = Time.zone.now

        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: 'Modchat', icon_url: 'https://cdn.discordapp.com/embed/avatars/0.png')

        embed.add_field(name: 'User',
                        value: "[#{modchat.user.username}](#{edit_admin_user_url(modchat.user)})", inline: true)
        embed.add_field(name: 'New Chat',
                        value: "[#{modchat.chat.uuid}](#{chat_url(modchat.chat.uuid)})",
                        inline: true)
      end
    end
  end

  def send_discord_modchat_message(modchat, message)
    return if Rails.env.test?
    return unless message.user

    Discord.webhook_client.execute do |builder|
      builder.add_embed do |embed|
        embed.color = 0x00FFFF
        embed.timestamp = Time.zone.now

        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: 'Modchat', icon_url: 'https://cdn.discordapp.com/embed/avatars/0.png')

        if message.user.admin?
          embed.add_field(name: 'User',
                          value: "[#{message.user.username}](#{edit_admin_user_url(message.user)}) (Staff)", inline: true) # rubocop:disable Layout/LineLength
        else
          embed.add_field(name: 'User',
                          value: "[#{message.user.username}](#{edit_admin_user_url(message.user)})", inline: true)
        end
        embed.add_field(name: 'Chat',
                        value: "[#{modchat.chat.uuid}](#{chat_url(modchat.chat.uuid)})",
                        inline: true)
        embed.add_field(name: 'Visibility', value: message.visibility)
        embed.add_field(name: 'Message',
                        value: message.content.truncate(1000))
      end
    end
  end

  def send_discord_modchat_status(modchat, user)
    return unless user

    Discord.webhook_client.execute do |builder|
      builder.add_embed do |embed|
        embed.color = 0x00FFFF
        embed.timestamp = Time.zone.now

        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: 'Modchat', icon_url: 'https://cdn.discordapp.com/embed/avatars/0.png')

        if user.admin?
          embed.add_field(name: 'User',
                          value: "[#{user.username}](#{edit_admin_user_url(user)}) (Staff)", inline: true)
        else
          embed.add_field(name: 'User',
                          value: "[#{user.username}](#{edit_admin_user_url(user)})", inline: true)
        end
        embed.add_field(name: 'Chat',
                        value: "[#{modchat.chat.uuid}](#{chat_url(modchat.chat.uuid)})",
                        inline: true)
        embed.add_field(name: 'Status',
                        value: modchat.status)
      end
    end
  end

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
