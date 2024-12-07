# frozen_string_literal: true

require 'discordrb/webhooks'

module Discord
  class << self
    def webhook_client
      @webhook_client ||= Discordrb::Webhooks::Client.new(url: ENV.fetch('DISCORD_WEBHOOK_URL'))
    end
  end
end
