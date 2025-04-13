# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class TagsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  include HideableController

  before_action :authenticate_user!
  before_action :set_tag, only: %i[show edit update destroy details]

  before_action :set_parent, only: %i[create update] # MUST be before set_synonym
  before_action :set_synonym, only: %i[create update]

  after_action :track_create, only: :create

  skip_before_action :verify_authenticity_token, raise: false, only: %i[autocomplete]

  authorize_resource

  # GET /tags
  # GET /tags.json
  def index
    @pagy, @tags = pagy(Tag.accessible_by(current_ability), items: 5)
  end

  # GET /tags/1
  # GET /tags/1.json
  def show; end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit; end

  # POST /tags
  # POST /tags.json
  def create
    @tag = Tag.new(tag_params)

    @tag.synonym = @synonym
    @tag.parent = @parent

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render :show, status: :created, location: @tag }
      else
        format.html { render :new }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tags/1
  # PATCH/PUT /tags/1.json
  def update
    @tag.synonym = @synonym
    @tag.parent = @parent
    @tag.save

    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: 'Tag was successfully updated.' }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit, alert: @tag.errors.full_messages }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag.destroy
    respond_to do |format|
      format.html { redirect_to tags_url, notice: 'Tag was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /tags/autocomplete
  # POST /tags/autocomplete.json
  def autocomplete
    if params[:tag_search].blank?
      @tags = Tag.where(tag_type: params[:tag_type],
                        polarity: params[:polarity])
                 .left_joins(:object_tags)
                 .group(:id).order('COUNT(object_tags.id) DESC')
                 .limit(25)
    else
      @tags_string = params[:tag_search].split(',')
      @search_string = @tags_string.last
      @tags = Tag.where('name ILIKE ?', "%#{@search_string}%")
                 .where(enabled: true,
                        synonym_id: nil,
                        tag_type: params[:tag_type],
                        polarity: params[:polarity])
                 .left_joins(:object_tags)
                 .group(:id).order('COUNT(object_tags.id) DESC')
                 .limit(25)
    end

    # Exclude things we make checkboxes for
    entry_tags = TagSchema.entries_for(params[:tag_type])
    @tags = @tags.where.not(name: entry_tags)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('autocomplete_results',
                              partial: 'tags/autocomplete_results',
                              locals: { tags: @tags, search_string: @search_string })
        ]
      end
      format.json { render json: @tags.as_json(only: %i[id name tag_type polarity tooltip details]) }
    end
  end

  def details
    respond_to do |format|
      format.html { render 'tags/details', tag: @tag }
    end
  end

  private

  # Saves us having to find tag by route params
  def set_tag
    Rails.logger.debug { "TAG ID !!!!!!!!!!!!!!!!!! #{params[:id]}" }
    @tag = Tag.find(params[:id])
  end

  # MUST run before set_synonym
  def set_parent
    @parent = nil

    return unless params.key?(:parent)

    missing_something = parent_params.empty? || (
      %w[name tag_type polarity].any? { |key| parent_params[key].blank? }
    )
    return if missing_something

    @parent = Tag.find_or_create_with_downcase(
      polarity: parent_params[:polarity],
      tag_type: parent_params[:tag_type],
      name: parent_params[:name]
    )
  end

  def set_synonym
    @synonym = nil

    # A tag cannot have both a synonym and a parent.
    return unless @parent.nil?

    return unless params.key?(:synonym)

    missing_something = synonym_params.empty? || (
      %w[name tag_type polarity].any? { |key| synonym_params[key].blank? }
    )
    return if missing_something

    @synonym = Tag.find_or_create_with_downcase(
      polarity: synonym_params[:polarity],
      tag_type: synonym_params[:tag_type],
      name: synonym_params[:name]
    )
  end

  def tag_params
    params.expect(tag: %i[name tag_type polarity enabled tooltip details]).compact_blank
  end

  def parent_params
    params.expect(parent: %i[name tag_type polarity]) if params.key?(:parent)
  end

  def synonym_params
    params.expect(synonym: %i[name tag_type polarity]) if params.key?(:synonym)
  end

  def autocomplete_params
    params.expect(tag: %i[tag_search tag_type polarity])
  end

  def track_create
    ahoy.track 'Tag Created', { user_id: current_user.id, tag_id: @tag.id }
  end
end
# rubocop:enable Metrics/ClassLength
