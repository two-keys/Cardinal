# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :notification_count, only: [:index]

  def index
    respond_to do |format|
      format.html { render partial: 'notifications', locals: { notifications: @notifications } }
    end
  end

  def notification_count
    @notifications = ChatUser.where(user: current_user, status: [:unread, :unanswered, :ended])
  end
end
