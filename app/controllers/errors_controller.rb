# frozen_string_literal: true

class ErrorsController < ApplicationController
  def internal_server_error
    @event_id = nil
    until @event_id
      @event_id = ReadCache.redis.get(request.uuid)
      sleep 0.1
    end
    @dsn = Sentry.configuration.dsn.to_s

    render status: :internal_server_error, locals: { event_id: @event_id, dsn: @dsn }
  end
end
