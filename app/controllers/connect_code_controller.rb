# frozen_string_literal: true

class ConnectCodeController < ApplicationController
  include ApplicationHelper

  before_action :set_connect_code, only: %i[update consume]
  before_action :authenticate_user!

  after_action :track_create, only: :create
  after_action :track_consume, only: :consume

  authorize_resource

  def create
    @chat = Chat.new
    @chat.save
    @connect_code = ConnectCode.new(chat: @chat, user: current_user, remaining_uses: 8)
    @connect_code.save!
    creation_message = "Chat created.  \n" \
                       "Connect code is: #{@connect_code.code}. It has #{@connect_code.remaining_uses} uses left."
    @chat.messages << Message.new(content: creation_message)
    @connect_code.use(current_user)
    chat_user = current_user.chat_users.find_by(chat: @chat)
    chat_user.ongoing!
    chat_user.role = ChatUser.roles[:chat_admin]
    respond_to do |format|
      format.html { redirect_to chat_path(@chat.uuid) }
      format.json { render :show, status: :created, location: @chat.uuid }
    end
  end

  # PATCH/PUT /chats/1 or /chats/1.json
  def update
    authorize! :update, @connect_code
    respond_to do |format|
      if @connect_code.update(
        {
          remaining_uses: update_connect_code_params[:remaining_uses],
          status: update_connect_code_params[:status],
          title: update_connect_code_params[:title],
          description: update_connect_code_params[:description]
        }
      )
        format.html { redirect_to edit_chat_path(@connect_code.chat.uuid), notice: 'Code was successfully updated.' }
        format.json { render :show, status: :ok, location: @connect_code.chat.uuid }
      else
        format.html { redirect_to edit_chat_path(@connect_code.chat.uuid), status: :unprocessable_entity }
        format.json { render json: @connect_code.errors, status: :unprocessable_entity }
      end
    end
  end

  def consume
    respond_to do |format|
      if !@connect_code.nil? && @connect_code.use(current_user)
        format.html { redirect_to chat_path(@connect_code.chat.uuid) }
        format.json { render :show, status: :ok, location: @connect_code.chat.uuid }
      else
        format.html { redirect_to chats_path }
        format.json { render :show, status: :unprocessable_entity }
      end
    end
  end

  def connect_code_params
    params.require(:connect_code)
  end

  def set_connect_code
    @connect_code = ConnectCode.find_by(code: params[:connect_code])
  end

  private

  def update_connect_code_params
    params.permit(:connect_code, :title, :description, :remaining_uses, :status)
  end

  def auth_redirect
    edit_chat_url(@connect_code.chat.uuid)
  end

  def track_create
    ahoy.track 'ConnectCode Created', { user_id: @connect_code.user.id, chat_id: @connect_code.chat.id }
  end

  def track_consume
    ahoy.track 'ConnectCode Consumed', { user_id: @connect_code.user.id, chat_id: @connect_code.chat.id }
  end
end
