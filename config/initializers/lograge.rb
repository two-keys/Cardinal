# frozen_string_literal: true

Rails.application.configure do
  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    {
      params: event.payload[:params] ? event.payload[:params].except(*exceptions) : nil,
      exception: event.payload[:exception], # ["ExceptionClass", "the message"]
      exception_object: event.payload[:exception_object] # the exception instance
    }
  end
  config.lograge.custom_payload do |controller|
    {
      host: controller.request.host,
      user_id: controller.current_user.try(:id)
    }
  end
  config.lograge.ignore_custom = lambda do |event|
    event.payload[:controller] == 'ActiveStorage::DiskController'
  end
end
