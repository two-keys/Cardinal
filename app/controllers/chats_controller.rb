# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ChatsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_chat, only: %i[show edit update destroy resolve_mod_chat chat_kick read forceongoing search]
  before_action :edit_chat_params, only: %i[update]
  before_action :authenticate_user!
  authorize_resource

  # GET /chats or /chats.json
  def index
    query = current_user.chat_users
    if params[:filter] && ChatUser.statuses.include?(params[:filter])
      query = if params[:filter] == 'ended' # Special case for ended / ended_viewed
                query.where(status: %w[ended ended_viewed])
              elsif params[:filter] != 'mod' # Special case for Mod Chats
                query.where(status: params[:filter])
              end
    end
    chat_ids = query.map(&:chat_id)
    chats_query = Chat.where(id: chat_ids).includes(messages: [:user])
    chats_query = chats_query.where.associated(:mod_chat) if params[:filter] == 'mod'
    @pagy, @chats = pagy(chats_query.order('updated_at DESC'), items: 20)
    respond_to do |format|
      format.html
      format.json { render json: @chats }
    end
  end

  # GET /chats/1 or /chats/1.json
  def show
    if @chat.nil?
      respond_to do |format|
        format.html { redirect_to chats_url, notice: 'This chat does not exist.' }
      end
    else
      @chat_user = @chat.chat_users.find_by(user: current_user)
      @pagy, @messages = pagy(@chat.messages.display.includes(:user), items: 20)
      @chat.viewed!(current_user) if @pagy.page == 1
    end
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

  def create_mod_chat
    @chat = Chat.new
    @chat.users << current_user
    respond_to do |format|
      if @chat.save
        @mod_chat = ModChat.new(user: current_user, chat: @chat)
        @mod_chat.save!
        creation_message = "Mod Chat created by #{current_user.chat_users.find_by(chat: @chat).icon}  \n" \
                           'What do you need help with? Staff will respond.'
        @chat.messages << Message.new(content: creation_message)
        format.html { redirect_to chat_path(@chat.uuid), notice: 'Mod Chat was successfully created.' }
        format.json { render :show, status: :created, location: @chat.uuid }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
      end
    end
  end

  def resolve_mod_chat
    @chat.mod_chat.resolved!
    @chat.mod_chat.alert_status_changed(current_user)
    respond_to do |format|
      format.html { redirect_to chat_path(@chat.uuid), notice: 'ModChat has been resolved.' }
      format.json { render :show, status: :ok, location: @chat.uuid }
    end
  end

  # PATCH/PUT /chats/1 or /chats/1.json
  def update
    respond_to do |format|
      prev_icon = @chat_info.icon
      if @chat_info.update(edit_chat_params)
        message_content = "#{icon_for prev_icon} is now #{icon_for params[:chat][:icon]}."
        @chat.messages << Message.new(content: message_content) if prev_icon != params[:chat][:icon]
        format.html { redirect_to edit_chat_path(@chat.uuid), notice: 'Chat was successfully updated.' }
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
      users_to_notify = @chat.chat_users.where.not(user: @chat.active_chat_users)
      users_to_notify.each do |u|
        u.user.push_subscriptions.each do |s|
          s.push('Chat Ended', 'Click to view', url: "/chats/#{@chat.uuid}")
        end
      end
    end
    @chat.messages << Message.new(content: "#{user_icon} has left the chat.")
    respond_to do |format|
      format.html { redirect_to chats_url, notice: 'Chat was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # DELETE/chats/1/🌮 or /chats/1/🌮.json
  def chat_kick
    target_user = @chat.chat_users.find_by(icon: params[:icon]).user
    @chat.users.delete(target_user)
    if @chat.users.empty?
      @chat.destroy
    elsif @chat.users.count == 1
      @chat.chat_users.each(&:ended!)
      users_to_notify = @chat.chat_users.where.not(user: @chat.active_chat_users)
      users_to_notify.each do |u|
        u.user.push_subscriptions.each do |s|
          s.push('Chat Ended', 'Click to view', url: "/chats/#{@chat.uuid}")
        end
      end
    end
    @chat.messages << Message.new(content: "#{params[:icon]} has left the chat.")
    respond_to do |format|
      format.html { redirect_to chats_url, notice: 'Chat user was successfully banned.' }
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

  # GET /chats/1/search?q=text
  def search
    @query = params[:q]
    results = params[:q].blank? ? @chat.messages.display.includes(:user) : @chat.search(@query)
    @pagy, @messages = pagy(results, items: 20)
  end

  # GET /notifications.json
  def notifications
    notifications = ChatUser.where(user: current_user, status: %i[unread unanswered ended])
    respond_to do |format|
      format.json do
        render template: '/application/_notifications', locals: { notifications: notifications }, layout: false
      end
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
    params.require(:chat).permit(:title, :description, :pseudonym_id, :icon, :color, :hide_latest)
  end

  def auth_redirect
    chats_url
  end
end
# rubocop:enable Metrics/ClassLength
