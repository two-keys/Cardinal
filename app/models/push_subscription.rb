# frozen_string_literal: true

class PushSubscription < ApplicationRecord
  belongs_to :user

  def push(title, message, url: nil)
    WebPushJob.perform_later(
      title: title,
      message: message,
      endpoint: endpoint,
      p256dh_key: p256dh_key,
      auth_key: auth_key,
      url: url
    )
  end
end
