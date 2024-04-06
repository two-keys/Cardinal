# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_start_time
  before_action :set_sentry_context
  before_action :set_unleash_context

  rescue_from CanCan::AccessDenied, with: :user_not_authorized

  # start concern initializers
  def searchable?
    false
  end

  def characterized?
    false
  end
  # end   concern initializers

  def set_start_time
    @start_time = Time.now.to_f
  end

  def set_sentry_context
    return if current_user.nil?

    Sentry.set_user(username: current_user.username, email: current_user.email, id: current_user.id)
  end

  def set_unleash_context
    @unleash_context = if current_user.nil?
                         Unleash::Context.new(
                           session_id: session.id,
                           remote_address: request.remote_ip
                         )
                       else
                         Unleash::Context.new(
                           session_id: session.id,
                           remote_address: request.remote_ip,
                           user_id: current_user.id
                         )
                       end
  end

  def user_not_authorized(exception)
    # auth_redirect should be defined per controller as a method
    final_auth_redirect = defined?(auth_redirect) ? auth_redirect : main_app.root_url
    respond_to do |format|
      format.html { redirect_to final_auth_redirect, notice: exception.message, status: :not_found }
      format.json { render nothing: true, status: :not_found }
    end
  end
end
