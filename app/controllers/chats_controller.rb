# frozen_string_literal: true

class ChatsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_chat, only: %i[show edit update destroy read forceongoing]
  before_action :edit_chat_params, only: %i[update]
  before_action :authenticate_user!
  before_action :authorized?, only: %i[show edit update destroy read forceongoing]

  authorize_resource

  # GET /chats or /chats.json
  def index
    @pagy, @chats = pagy(current_user.chats.order('updated_at DESC'), items: 20)
    respond_to do |format|
      format.html
      format.json { render json: @chats }
    end
  end

  # GET /chats/1 or /chats/1.json
  def show
    @pagy, @messages = pagy(@chat.messages.display, items: 20)
    @chat.viewed!(current_user) if @pagy.page == 1
  end

  # GET /chats/new
  def new
    @chat = Chat.new
  end

  # GET /chats/1/edit
  def edit; end

  # POST /chats or /chats.json
  def create
    @chat = Chat.new
    @chat.users << current_user
    respond_to do |format|
      if @chat.save
        @connect_code = ConnectCode.new(chat_id: @chat.id, user: current_user, remaining_uses: 9)
        @connect_code.save!
        creation_message = "Chat created by #{current_user.chat_users.find_by(chat: @chat).icon}  \n" \
                           "Connect code is: #{@connect_code.code}. It has #{@connect_code.remaining_uses} uses left."
        @chat.messages << Message.new(content: creation_message)
        format.html { redirect_to chat_path(@chat.uuid), notice: 'Chat was successfully created.' }
        format.json { render :show, status: :created, location: @chat.uuid }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chats/1 or /chats/1.json
  def update
    respond_to do |format|
      if @chat_info.update({ title: params[:chat][:title], description: params[:chat][:description] })
        format.html { redirect_to chat_path(@chat.uuid), notice: 'Chat was successfully updated.' }
        format.json { render :show, status: :ok, location: @chat.uuid }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chats/1 or /chats/1.json
  def destroy
    user_icon = current_user.chat_users.find_by(chat: @chat).icon
    @chat.users.delete(current_user)
    if @chat.users.empty?
      @chat.destroy
    elsif @chat.users.count == 1
      @chat.chat_users.each(&:ended!)
    end
    @chat.messages << Message.new(content: "#{user_icon} has left the chat.")
    respond_to do |format|
      format.html { redirect_to chats_url, notice: 'Chat was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /chats/1/forceongoing
  def forceongoing
    chat_user = @chat.chat_users.find_by(user: current_user)
    chat_user.ongoing!
    respond_to do |format|
      format.html { redirect_to edit_chat_path(@chat.uuid), notice: 'Chat was successfully updated.' }
      format.json { render :show, status: :ok, location: @chat.uuid }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_chat
    @chat = Chat.find_by(uuid: params[:id])
    @chat_info = @chat.get_user_info(current_user) unless @chat.nil?
    @format = params[:format]
  end

  # Only allow a list of trusted parameters through.
  def create_chat_params
    params.require(:chat).permit(nil)
  end

  def edit_chat_params
    params.require(:chat).permit(:title, :description)
  end

  def authorized?
    return if !@chat.nil? && @chat.users.include?(current_user)

    redirect_to chats_path
  end
end
