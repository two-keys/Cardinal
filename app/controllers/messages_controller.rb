# frozen_string_literal: true

class MessagesController < ApplicationController
  include AuditableController

  before_action :set_message, only: %i[show edit update destroy]
  before_action :authenticate_user!

  after_action :track_create, only: :create
  after_action :track_edit, only: :update

  authorize_resource

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
    @message.color = ChatUser.find_by(user: @message.user, chat: @message.chat)&.color
  end

  # GET /messages/1/edit
  def edit; end

  # POST /messages or /messages.json
  def create # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    @message = Message.new(message_params)
    @message.user = current_user
    authorize! :create, @message
    last_message = @message.chat&.messages&.last

    # Hacky protection against duplicate sends until I can debug what is going wrong.
    if last_message && last_message.content == @message.content && last_message.user_id == @message.user_id
      respond_to do |format|
        format.html do
          render partial: 'messages/form',
                 locals: { locals: { message: Message.new(color: @message.color),
                                     chat_id: @message.chat.id } }
        end
        format.json { render json: { warning: 'Ignoring duplicate message' } }
      end

      return
    end

    respond_to do |format|
      if @message.save
        ChatUser.find_by(chat: @message.chat, user: @message.user)&.update(color: @message.color)
        format.html do
          render partial: 'messages/form',
                 locals: { locals: { message: Message.new(color: @message.color),
                                     chat_id: @message.chat.id } }
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

  private

  def model_class
    'message'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def message_params
    if Current.user&.admin?
      return params.require(:message).permit(:content, :visibility, :color, :chat_id,
                                             :icon).compact_blank
    end

    params.require(:message).permit(:content, :visibility, :color, :chat_id).compact_blank
  end

  def track_create
    ahoy.track 'Message Created', { chat_id: @message.chat_id, user_id: @message.user_id }
  end

  def track_edit
    ahoy.track 'Message Edited', { chat_id: @message.chat_id, user_id: @message.user_id }
  end
end
