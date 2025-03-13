# frozen_string_literal: true

json.unread do
  json.array! notifications.where(status: :unread) do |notification|
    json.extract! notification, :id, :title, :description
    json.chat_url chat_url(notification.chat.uuid)
    json.latest_message do
      json.extract! notification.chat.messages.last, :id, :icon, :content
    end
  end
end

json.unanswered do
  json.array! notifications.where(status: :unanswered) do |notification|
    json.extract! notification, :id, :title, :description
    json.chat_url chat_url(notification.chat.uuid)
    json.latest_message do
      json.extract! notification.chat.messages.last, :id, :icon, :content
    end
  end
end

json.ended do
  json.array! notifications.where(status: :ended) do |notification|
    json.extract! notification, :id, :title, :description
    json.chat_url chat_url(notification.chat.uuid)
    json.latest_message do
      json.extract! notification.chat.messages.last, :id, :icon, :content
    end
  end
end
