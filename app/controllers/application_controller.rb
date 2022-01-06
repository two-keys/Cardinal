# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_start_time
  before_action :set_sentry_context

  def set_start_time
    @start_time = Time.now.to_f
  end

  def set_sentry_context
    return if current_user.nil?

    Sentry.set_user(username: current_user.username, email: current_user.email, id: current_user.id)
  end
end
