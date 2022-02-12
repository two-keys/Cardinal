# frozen_string_literal: true

class PromptsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_prompt, only: %i[show edit bump update update_tags destroy]
  before_action :authenticate_user!
  before_action :authorized?, only: %i[edit bump update update_tags destroy]
  before_action :visible?, only: %i[show]

  # GET /prompts
  def index
    @pagy, @prompts = pagy(Prompt.where(status: 'posted').or(Prompt.where(user_id: current_user.id)), items: 5)
  end

  # GET /prompts/1
  def show; end

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
    params.require(:prompt).permit(:starter, :ooc, :status)
  end

  def tag_params
    params.require(:tags).permit(**CardinalSettings::Tags.allowed_type_params)
  end

  def visible?
    return if @prompt.posted? || @prompt.user_id == current_user.id || admin?

    raise ActiveRecord::RecordNotFound.new, "Couldn't find Prompt with 'id'=#{@prompt.id}"
  end

  def authorized?
    return if @prompt.user_id == current_user.id || admin?

    redirect_to root_path, alert: 'You are not authorized to edit this prompt.'
  end
end
