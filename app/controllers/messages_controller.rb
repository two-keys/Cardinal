# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_message, only: %i[show edit update destroy]
  before_action :viewed, only: %i[show]
  before_action :authenticate_user!
  before_action :authorized?, only: %i[edit update destroy]
  before_action :authorized_create?, only: [:create]

  # GET /messages or /messages.json
  def index
    @messages = Message.all
  end

  # GET /messages/1 or /messages/1.json
  def show
    respond_to do |format|
      format.html { render @message, locals: { locals: { message: @message, current_user_id: current_user.id } } }
      format.json { render :show, status: :ok, location: @message }
    end
  end

  # GET /messages/new
  def new
    @message = Message.new(message_params)
  end

  # GET /messages/1/edit
  def edit; end

  # POST /messages or /messages.json
  def create
    respond_to do |format|
      if @message.save
        format.html do
          render partial: 'messages/form', locals: { locals: { message: Message.new, chat_id: @message.chat.id } }
        end
        format.json { render :show, status: :created, location: @message }
      else
        format.html do
          render partial: 'messages/form', locals: { locals: { message: @message, chat_id: @message.chat.id } }
        end
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /messages/1 or /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { head :ok }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html do
          render partial: 'messages/form', locals: { locals: { message: @message, chat_id: @message.chat.id } }
        end
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1 or /messages/1.json
  def destroy
    @message.destroy

    respond_to do |format|
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def viewed
    @message.chat.viewed(current_user) if @message == @message.chat.messages.last
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def message_params
    params.require(:message).permit(:content, :ooc, :user_id, :chat_id)
  end

  def authorized?
    return unless @message.user_id != current_user.id || !current_user.joined?(@message.chat)

    redirect_to root_path, alert: 'You are not authorized to edit this message.'
  end

  def authorized_create?
    @message = Message.new(message_params)

    return if current_user.joined?(@message.chat)

    redirect_to root_path, alert: 'You are not authorized to create a message in this chat.'
  end
end
