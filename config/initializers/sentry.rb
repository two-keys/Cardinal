# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://c844309d409e4ad9a87377b255224291@sentry.roleply.site/2'
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |_context|
    true
  end

  config.before_send = lambda do |event, _hint|
    Redis.current.set(event.tags[:request_id], event.event_id)
    Redis.current.expire(event.tags[:request_id], 15.seconds)

    event
  end
end
