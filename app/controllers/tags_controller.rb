# frozen_string_literal: true

class TagsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :require_admin, only: %i[new edit create update destroy]
  before_action :set_tag, only: %i[show edit update destroy]
  before_action :set_parent, only: %i[create update] # MUST be before set_synonym
  before_action :set_synonym, only: %i[create update]

  # GET /tags
  # GET /tags.json
  def index
    @pagy, @tags = pagy(Tag.all, items: 5)
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
    @tag.name = tag_params[:name]
    @tag.tag_type = tag_params[:tag_type]

    @tag.synonym = @synonym
    @tag.parent = @parent

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: 'Tag was successfully updated.' }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit }
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

  private

  # Saves us having to find tag by route params
  def set_tag
    @tag = Tag.find(params[:id])
  end

  # MUST run before set_synonym
  def set_parent
    @parent = nil

    return if parent_params.empty? || parent_params[:name].empty? || parent_params[:tag_type].empty?

    @parent = Tag.find_or_create_by!(parent_params)
  end

  def set_synonym
    @synonym = nil

    # A tag cannot have both a synonym and a parent.
    return unless @parent.nil?

    return if synonym_params.empty? || synonym_params[:name].empty? || synonym_params[:tag_type].empty?

    @synonym = Tag.find_or_create_by!(synonym_params)
  end

  def tag_params
    params.require(:tag).permit(:name, :tag_type)
  end

  def parent_params
    params.require(:parent).permit(:name, :tag_type)
  end

  def synonym_params
    params.require(:synonym).permit(:name, :tag_type)
  end
end
