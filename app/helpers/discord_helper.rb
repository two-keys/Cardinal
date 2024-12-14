# frozen_string_literal: true

module DiscordHelper
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
                          value: "[#{alertable.class}](#{url_for([:admin, alertable])})", inline: true)
        else
          embed.add_field(name: 'Alerted Content',
                          value: "[#{alertable.class}](#{url_for(alertable)})", inline: true)
        end

        embed.add_field(name: 'Alerted Text',
                        value: alertable.content.truncate(1024), inline: false)
      end
    end
  end

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
