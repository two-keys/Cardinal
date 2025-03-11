# frozen_string_literal: true

class WebPushJob < ApplicationJob
  queue_as :default

  def perform(title:, message:, endpoint:, p256dh_key:, auth_key:, url:) # rubocop:disable Metrics/ParameterLists
    message_json = {
      title: title,
      body: message,
      icon: ActionController::Base.helpers.asset_url('icon.png'),
      url: url || "http://#{ENV.fetch('BASE_URL', 'localhost:3000')}"
    }.to_json

    WebPush.payload_send(
      message: message_json,
      endpoint: endpoint,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: {
        subject: ENV.fetch('WEBPUSH_SUBJECT', nil),
        public_key: ENV.fetch('WEBPUSH_PUBLIC_KEY', nil),
        private_key: ENV.fetch('WEBPUSH_PRIVATE_KEY', nil)
      },
      url: url || ENV.fetch('BASE_URL', 'localhost:3000')
    )
  end
end
