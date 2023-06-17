# frozen_string_literal: true

Unleash.configure do |config|
  config.app_name = Rails.application.class.module_parent.to_s
  config.url      = ENV.fetch('UNLEASH_API', 'https://flags.dreambubble.xyz/api/')
  # config.instance_id = "#{Socket.gethostname}"
  config.logger   = Logger.new(Rails.root.join('log/unleash.log'))
  config.environment = Rails.env
  config.custom_http_headers = { Authorization: ENV.fetch('UNLEASH_API_TOKEN', nil) }
end

UNLEASH = Unleash::Client.new

Rails.application.console do
  Rails.configuration.unleash = Unleash::Client.new
end
