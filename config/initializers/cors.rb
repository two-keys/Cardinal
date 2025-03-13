# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    base_url = ENV['BASE_URL'] || nil
    if base_url.nil?
      origins(%r{^https?://localhost:3000})
    else
      origins "https://#{ENV.fetch('BASE_URL')}", "http://#{ENV.fetch('BASE_URL')}"
    end
    resource '*', headers: :any, methods: %i[get post patch put]
  end
end
