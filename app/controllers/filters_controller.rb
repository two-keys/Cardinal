# frozen_string_literal: true

class FiltersController < ApplicationController
  include Pagy::Backend
  before_action :set_filter, only: %i[show edit update destroy]
  before_action :authenticate_user!

  load_and_authorize_resource

  # GET /filters or /filters.json
  def index
    query = Filter.accessible_by(current_ability).order(group: :asc, priority: :desc)

    # GET /filters?group=default
    query = query.where(group: search_params[:group]) if search_params.key?(:group)

    @pagy, @filters = pagy(query, items: 5)
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

  def filter_params
    params.require(:filter).permit(:group, :filter_type, :priority)
  end

  def tag_params
    params.require(:tag).permit(:polarity, :tag_type, :name)
  end

  def search_params
    params.permit(:group)
  end

  def auth_redirect
    filters_url
  end
end
