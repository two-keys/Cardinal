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
    notifications = ChatUser.where(user: current_user, status: %i[unread unanswered ended])
    unread_count = notifications.where(status: :unread).count
    unanswered_count = notifications.where(status: :unanswered).count
    ended_count = notifications.where(status: :ended).count
    @notifications = { unread: unread_count, unanswered: unanswered_count, ended: ended_count }
  end
end
