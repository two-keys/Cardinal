# frozen_string_literal: true

module Admin
  class MessagesController < ApplicationController
    include Pagy::Backend
    include ApplicationHelper

    before_action :require_admin

    # POST /admin/messages or /admin/messages.json
    def create
      @message = Message.new(message_params)
      @message.user = nil

      respond_to do |format|
        if @message.save
          format.html do
            render partial: 'admin/messages/form',
                   locals: { locals: { message: Message.new, chat_id: @message.chat.id } }
          end
          format.json { render :show, status: :created, location: @message }
        else
          format.html do
            render partial: 'admin/messages/form',
                   locals: { locals: { message: @message, chat_id: @message.chat.id } }
          end
          format.json { render json: @message.errors, status: :unprocessable_entity }
        end
      end
    end

    def search
      @query = params[:q]
      results = @query.blank? ? Message.display(current_user).includes(:user, :chat) : Message.search(@query)
      @pagy, @messages = pagy(results, items: 20)
    end

    # Only allow a list of trusted parameters through
    def message_params
      params.expect(message: %i[content chat_id])
    end
  end
end
