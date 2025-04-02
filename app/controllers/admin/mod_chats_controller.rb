# frozen_string_literal: true

module Admin
  class ModChatsController < Admin::AdminPanelController
    include Pagy::Backend

    def index
      query = ModChat.includes(:chat, :user)

      # Apply filters
      query = query.where(status: params[:status]) if params[:status].present?
      user = User.find_by(username: params[:user]) if params[:user].present?
      query = query.where(user:) if user
      @pagy, @mod_chats = pagy(query, items: 25)
    end
  end
end
