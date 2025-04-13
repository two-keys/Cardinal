# frozen_string_literal: true

class FiltersController < ApplicationController # rubocop:disable Metrics/ClassLength
  include Pagy::Backend
  before_action :set_filter, only: %i[show edit update destroy]
  before_action :set_default_simple, only: %i[simple]
  before_action :authenticate_user!

  load_and_authorize_resource

  include SearchableController

  def self.search_keys
    %i[group]
  end

  # GET /filters or /filters.json
  def index
    query = Filter.accessible_by(current_ability).order(group: :asc, priority: :desc)

    # GET /filters?group=default
    query = query.where(group: search_params[:group]) if search_params.key?(:group)

    @pagy, @filters = pagy(query.includes(:user, target: [:synonym]), items: 25)
  end

  # GET /filters/1 or /filters/1.json
  def show; end

  # GET /filters/new
  def new
    @filter = Filter.new
  end

  # GET /filters/1/edit
  def edit; end

  # POST /filters or /filters.json
  def create
    @filter = Filter.new(filter_params)
    @filter.user_id = current_user.id
    @filter.target = Tag.find_or_create_with_downcase(
      polarity: tag_params[:polarity],
      tag_type: tag_params[:tag_type],
      name: tag_params[:name]
    )

    respond_to do |format|
      if @filter.save
        format.html { redirect_to filter_url(@filter), notice: 'Filter was successfully created.' }
        format.json { render :show, status: :created, location: @filter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /filters/simple
  def simple; end

  # POST /filters/simple
  def create_simple
    tag_params = params.expect(tags: [**TagSchema.allowed_type_params])

    success = Filter.from_tag_params(tag_params, Current.user, params[:variant])

    respond_to do |format|
      if success
        format.html { redirect_to filters_path(group: 'simple'), notice: 'Filters were successfully created.' }
        format.json { render :show, status: :ok, location: filters_path(group: 'simple') }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: 'There was an error creating your simple filters', status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /filters/1 or /filters/1.json
  def update
    @filter.assign_attributes(filter_params)

    respond_to do |format|
      if @filter.save
        format.html { redirect_to filter_url(@filter), notice: 'Filter was successfully updated.' }
        format.json { render :show, status: :ok, location: @filter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /filters/1 or /filters/1.json
  def destroy
    @filter.destroy

    respond_to do |format|
      format.html { redirect_to filters_url, notice: 'Filter was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_filter
    @filter = Filter.find(params[:id])
  end

  # set @default_simple tags
  def set_default_simple
    filter_type = params[:variant] == 'whitelist' ? 'Exception' : 'Rejection'

    @default_simple = {}
    TagSchema.polarities.each do |pol|
      @default_simple.store(pol, {})
      TagSchema.allowed_types_for(pol).each do |a_type|
        @default_simple[pol].store(a_type, [])
      end
    end

    Tag.joins(:filters).where(
      filters: { user: Current.user, filter_type:, group: 'simple' }
    ).find_each do |tag|
      polarity = tag.polarity
      tag_type = tag.tag_type

      @default_simple[polarity][tag_type].push([tag.name, tag.tooltip, tag.details, tag.id])
    end

    @default_simple
  end

  def filter_params
    params.expect(filter: %i[group filter_type priority])
  end

  def tag_params
    params.expect(tag: %i[polarity tag_type name])
  end

  def auth_redirect
    filters_url
  end
end
