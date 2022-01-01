# frozen_string_literal: true

class ChatsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_chat, only: %i[show edit update destroy read]
  before_action :edit_chat_params, only: %i[update]
  before_action :authenticate_user!
  before_action :authorized?, only: %i[show edit update destroy read]

  # GET /chats or /chats.json
  def index
    @pagy, @chats = pagy(current_user.chats.order('updated_at DESC'), items: 20)
    respond_to do |format|
      format.html
      format.json { render json: @chats }
      format.turbo_stream { render redirect_to chats_path }
    end
  end

  # GET /chats/1 or /chats/1.json
  def show
    @chat.set_viewed(current_user)
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
        @chat.messages << Message.new(content: "Chat created by #{current_user.chat_users.find_by(chat: @chat).icon}  \nConnect code is: #{@connect_code.code}. It has #{@connect_code.remaining_uses} uses left.")
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
    @chat.users.delete(current_user)
    @chat.messages << Message.new(content: 'User left the chat.')
    if @chat.users.empty?
      @chat.destroy
    elsif @chat.users.count == 1
      @chat.chat_users.each(&:ended!)
    else
      @chat.chat_users.each(&:unread!)
    end
    respond_to do |format|
      format.html { redirect_to chats_url, notice: 'Chat was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_chat
    @chat = Chat.find_by(uuid: params[:id])
    @chat_info = @chat.get_user_info(current_user)
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
    return if @chat.users.include?(current_user)
    redirect_to chats_path
  end
end
