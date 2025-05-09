# frozen_string_literal: true

## Prompts controller is inevitably going to have a lot that goes into it
## tag searching, prompts, updates, etc
# rubocop:disable Metrics/ClassLength
class PromptsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_prompt, only: %i[show edit bump update answer destroy]
  before_action :set_bump_pseudonym_options, only: %i[bump]
  before_action :authenticate_user!

  after_action :track_create, only: :create
  after_action :track_edit, only: :update
  after_action :track_answer, only: :answer
  after_action :track_lucky_dip, only: :lucky_dip

  authorize_resource

  include TaggableController
  include SearchableController
  include PseudableController
  include CharacterizedController
  include AuditableController
  include CursorPaginatable

  def self.search_keys
    %i[before tags nottags managed ismine]
  end

  # GET /prompts
  def index
    query = add_search(Prompt)

    # prompt specific search

    # can chats from the prompt be moderated?
    query = query.where(managed: search_params[:managed]) if search_params.key?(:managed)

    # shadowban logic
    unless current_user.shadowbanned? || current_user.admin?
      query = query.where.not(user_id: User.where(shadowbanned: true).select(:id))
    end

    @prompts, @cursor = paginate_with_cursor(query.includes(:user, :pseudonym, :tags, :object_tags), by: :bumped_at,
                                                                                                     before: params[:before]) # rubocop:disable Layout/LineLength
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

    @pagy, @chats = pagy(query, items: 5)
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
      @chat = nil
      @chat = @prompt.answer(current_user)
      if @chat.save!
        @connect_code = ConnectCode.new(
          chat_id: @chat.id,
          user: @prompt.user,
          remaining_uses: @prompt.default_slots - 2,
          status: @prompt.managed? ? :unlisted : :listed
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

  # GET /prompts/lucky_dip
  def lucky_dip
    prompt_max = Prompt.last.id
    # First apply all filters (including blacklists) to create a base query
    base_query = add_search(Prompt.not_shadowbanned.where(status: 'posted'))

    random_prompt = if prompt_max >= 1000
                      # More efficient random selection using PostgreSQL's TABLESAMPLE
                      # This avoids the expensive COUNT operation
                      base_query
                        .from("#{Prompt.table_name} TABLESAMPLE BERNOULLI(1)")
                        .order('RANDOM()')
                        .first
                    else
                      base_query.sample
                    end

    if random_prompt
      @prompt = random_prompt
      redirect_to prompt_url(random_prompt)
    else
      # Fall back to a different method if TABLESAMPLE returns no results
      # This handles edge cases with heavily filtered prompts
      fallback_prompt = base_query.order('RANDOM()').first

      if fallback_prompt
        redirect_to prompt_url(fallback_prompt)
      else
        redirect_to prompts_url, notice: 'No matching prompts found for Lucky Dip.'
      end
    end
  end

  private

  def model_class
    'prompt'
  end

  def set_bump_pseudonym_options
    set_pseudonym_options
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_prompt
    @prompt = Prompt.find(params[:id] || params[:prompt_id])
  end

  # Only allow a list of trusted parameters through.
  def prompt_params
    params.expect(prompt: %i[starter ooc color status default_slots managed pseudonym_id])
  end

  def track_create
    ahoy.track 'Prompt Created', { user_id: @prompt.user.id }

    @prompt.tags.each do |tag|
      ahoy.track 'Tag Used', { tag_id: tag.id, prompt_id: @prompt.id }
    end
  end

  def track_edit
    ahoy.track 'Prompt Edited', { user_id: @prompt.user.id, prompt_id: @prompt.id }

    @prompt.tags.each do |tag|
      ahoy.track 'Tag Used', { tag_id: tag.id, prompt_id: @prompt.id }
    end
  end

  def track_answer
    ahoy.track 'Prompt Answered', { user_id: @prompt.user.id, prompt_id: @prompt.id, taker_id: current_user.id }
    ahoy.track 'ConnectCode Consumed', { user_id: @connect_code.user.id, chat_id: @chat.id }
    ahoy.track 'ConnectCode Consumed', { user_id: current_user.id, chat_id: @chat.id }
  end

  def track_lucky_dip
    ahoy.track 'Prompt Lucky Dipped', { user_id: current_user.id, prompt_id: @prompt.id, prompt_user: @prompt.user.id }
  end
end
# rubocop:enable Metrics/ClassLength
