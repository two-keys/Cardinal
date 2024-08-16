# frozen_string_literal: true

## Prompts controller is inevitably going to have a lot that goes into it
## tag searching, prompts, updates, etc
# rubocop:disable Metrics/ClassLength
class PromptsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_prompt, only: %i[show edit bump update answer destroy]
  before_action :authenticate_user!

  authorize_resource

  include SearchableController
  include PseudableController
  include CharacterizedController

  # GET /prompts
  def index
    query = add_search(Prompt)

    # prompt specific search

    # can chats from the prompt be moderated?
    query = query.where(managed: search_params[:managed]) if search_params.key?(:managed)

    # is this your prompt?
    if search_params.key?(:myprompts)
      query = if search_params[:myprompts] == 'true'
                query.where(user: current_user)
              else
                query.where.not(user: current_user)
              end
    end

    @pagy, @prompts = pagy(query, items: 5)
  end

  # GET /prompts/1
  def show
    query = @prompt.chats

    query = query.where(
      connect_code: ConnectCode.where(
        status: 'listed',
        remaining_uses: 1..
      )
    )
    # We could add more qualifiers here later, if we think we need to. For now, it should be fine.

    @chats = query
  end

  # GET /prompts/new
  def new
    @prompt = Prompt.new
  end

  # GET /prompts/1/edit
  def edit; end

  # POST /prompts
  def create
    @prompt = Prompt.new(prompt_params)
    @prompt.user_id = current_user.id

    added_tags = @prompt.add_tags(tag_params)
    added_characters = @prompt.add_characters(character_params)

    respond_to do |format|
      if added_tags && added_characters && @prompt.save
        format.html { redirect_to prompt_url(@prompt), notice: 'Prompt was successfully created.' }
        format.json { render :show, status: :created, location: @prompt }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @prompt.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /prompts/1/bump
  def bump
    respond_to do |format|
      if @prompt.bump!
        format.html { redirect_to prompt_url(@prompt), notice: 'Prompt was successfully bumped.' }
        format.json { render :show, status: :ok, location: @prompt }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @prompt.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /prompts/1
  def update
    respond_to do |format|
      if @prompt.update(prompt_params)
        format.html { redirect_to prompt_url(@prompt), notice: 'Prompt was successfully updated.' }
        format.json { render :show, status: :ok, location: @prompt }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @prompt.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /prompts/1/answer
  def answer
    respond_to do |format|
      @chat = @prompt.answer(current_user)
      if @chat.save
        @connect_code = ConnectCode.new(
          chat_id: @chat.id,
          user: @prompt.user,
          remaining_uses: @prompt.default_slots - 2
        )
        @connect_code.save!
        creation_message = "Chat created.  \n" \
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

  # DELETE /prompts/1
  def destroy
    @prompt.destroy

    respond_to do |format|
      format.html { redirect_to prompts_url, notice: 'Prompt was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_prompt
    @prompt = Prompt.find(params[:id] || params[:prompt_id])
  end

  # Only allow a list of trusted parameters through.
  def prompt_params
    params.require(:prompt).permit(:starter, :ooc, :status, :default_slots, :managed, :pseudonym_id)
  end

  def search_params
    params.permit(:before, :tags, :nottags, :managed, :myprompts)
  end
end
# rubocop:enable Metrics/ClassLength
