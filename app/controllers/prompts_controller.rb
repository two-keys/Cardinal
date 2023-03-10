# frozen_string_literal: true

## Prompts controller is inevitably going to have a lot that goes into it
## tag searching, prompts, updates, etc
# rubocop:disable Metrics/ClassLength
class PromptsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_prompt, only: %i[show edit bump update update_tags answer destroy]
  before_action :authenticate_user!

  authorize_resource

  # GET /prompts
  def index
    query = Prompt.accessible_by(current_ability)

    # GET /prompts?before=2022-02-17
    query = query.where(bumped_at: ..search_params[:before]) if search_params.key?(:before)

    # GET /prompts?nottags=meta:type:Violent,polarity:tag_type:name,...
    # NOT search, should run before general AND
    # this ensures you won't see prompts with ANY of the tags in nottags
    if search_params.key?(:nottags)
      # logger.debug search_params[:nottags]
      query_tags = Tag.from_search_params(search_params[:nottags])
      query_tag_ids = query_tags.map(&:id)
      # logger.debug query_tag_ids
      query = query.where(
        'NOT(ARRAY[?]::bigint[] && array(?))', # no overlap
        query_tag_ids, ObjectTag.where('object_type = \'Prompt\' AND object_id = "prompts"."id"').select(:tag_id)
      )
    end

    # GET /prompts?tags=meta:type:Violent,polarity:tag_type:name,...
    # AND search
    if search_params.key?(:tags)
      # logger.debug search_params[:tags]
      query_tags = Tag.from_search_params(search_params[:tags])
      query_tag_ids = query_tags.map(&:id)
      # logger.debug query_tag_ids
      query = query.where(
        'ARRAY[?]::bigint[] <@ array(?)',
        query_tag_ids, ObjectTag.where('object_type = \'Prompt\' AND object_id = "prompts"."id"').select(:tag_id)
      )
    end

    # GET /prompts
    # This is the ugliest code I've ever written,
    # but it should be fine as long we don't do string interpolation anywhere
    if Filter.exists?(user: current_user)
      f2 = Filter.arel_table.alias
      query = query.where.not(
        # We want prompts that don't have a tag mathcing a Rejection filter
        Filter.where(
          # Do any of the prompt's tags hit the rejection filter?
          '"filters"."tag_id" IN (?)',
          ObjectTag.where(
            '"object_tags"."object_type" = \'Prompt\' AND "object_tags"."object_id" = "prompts"."id"'
          ).select(:tag_id)
        ).where(
          # We could theoretically let people specify the specific filters they want to match,
          # but that sounds like a pain
          # `group: ['default', etc...]`
          filter_type: 'Rejection',
          user: current_user
        ).where.not(
          # If a prompt DOES have a tag matching a Rejection filter,
          # we can let that slide IF an Exception filter in the same group overrides that
          Filter.from(f2).select('"filters_2".*').where(
            # Same check as above, but Rails doesn't have a clean table alias feature even with arel_table
            '"filters_2"."tag_id" IN (?)',
            ObjectTag.where(
              '"object_tags"."object_type" = \'Prompt\' AND "object_tags"."object_id" = "prompts"."id"'
            ).select(:tag_id)
          ).where(
            '"filters_2"."filter_type" = ?', 'Exception'
          ).where(
            # as above so below
            '"filters_2"."group" = "filters"."group"',
            '"filters_2"."user_id" = "filters"."user_id"'
          ).where(
            # An exception filter with a higher priority always wins within a filter group
            '"filters_2"."priority" >= "filters"."priority"'
          ).arel.exists
        ).arel.exists
      )
    end

    @pagy, @prompts = pagy(query, items: 5)
  end

  # GET /prompts/search
  def search; end

  # POST /prompts/search
  def generate_search
    tags = Tag.from_tag_params(tag_params)
    tag_strings = tags.map do |tag|
      "#{tag[:polarity]}:#{tag[:tag_type]}:#{tag[:name]}"
    end

    previous_tag_param_string = search_params.key?('tags') ? "#{search_params[:tags]}," : ''

    redirect_to prompts_url search_params.merge(tags: "#{previous_tag_param_string}#{tag_strings.join(',')}")
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

    respond_to do |format|
      if added_tags && @prompt.save
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

  # PATCH/PUT /prompts/1/tags
  def update_tags
    added_tags = @prompt.add_tags(tag_params)

    respond_to do |format|
      if added_tags && @prompt.save
        format.html { redirect_to prompt_url(@prompt), notice: 'Tags were successfully updated.' }
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
    params.require(:prompt).permit(:starter, :ooc, :status, :default_slots)
  end

  def tag_params
    params.require(:tags).permit(**CardinalSettings::Tags.allowed_type_params)
  end

  def search_params
    params.permit(:before, :tags, :nottags)
  end
end
# rubocop:enable Metrics/ClassLength
