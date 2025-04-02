# frozen_string_literal: true

class ModChat < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  enum :status, { unanswered: 0, ongoing: 1, resolved: 2 }

  after_create_commit :alert_create
  before_update :send_message

  def send_message # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    if status_changed? && resolved? && status_was != 'resolved'
      chat.messages << Message.new(content: 'This Mod Chat has been resolved.',
                                   silent: true)
      chat.chat_users.each(&:ended!)
    end
    return unless status_changed? && status != 'resolved' && status_was == 'resolved'

    chat.messages << Message.new(content: 'This Mod Chat has been reopened.',
                                 silent: true)
    chat.chat_users.each(&:unread!)
  end

  def alert_create
    ApplicationController.helpers.send_discord_new_modchat(self)
  end

  def alert_new_message(message)
    ApplicationController.helpers.send_discord_modchat_message(self, message)
  end

  def alert_status_changed(user)
    ApplicationController.helpers.send_discord_modchat_status(self, user)
  end
end
