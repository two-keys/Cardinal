# frozen_string_literal: true

class PseudonymsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_pseudonym, only: %i[show edit update destroy]
  before_action :authenticate_user!

  authorize_resource

  include SearchableController

  def self.search_keys
    %i[before]
  end

  # GET /pseudonyms
  def index
    query = Pseudonym.accessible_by(current_ability)

    @pagy, @pseudonyms = pagy(query, items: 5)
  end

  # GET /pseudonyms/1
  def show; end

  # GET /pseudonyms/new
  def new
    @pseudonym = Pseudonym.new
  end

  # GET /pseudonyms/1/edit
  def edit; end

  # POST /pseudonyms
  def create
    @pseudonym = Pseudonym.new(pseudonym_params)
    @pseudonym.user_id = current_user.id

    respond_to do |format|
      if @pseudonym.save
        format.html { redirect_to pseudonym_url(@pseudonym), notice: 'Pseudonym was successfully created.' }
        format.json { render :show, status: :created, location: @pseudonym }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pseudonym.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pseudonyms/1
  def update
    respond_to do |format|
      if @pseudonym.update(pseudonym_params)
        format.html { redirect_to pseudonym_url(@pseudonym), notice: 'Pseudonym was successfully updated.' }
        format.json { render :show, status: :ok, location: @pseudonym }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pseudonym.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pseudonyms/1
  def destroy
    @pseudonym.destroy

    respond_to do |format|
      format.html { redirect_to pseudonyms_url, notice: 'Pseudonym was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_pseudonym
    @pseudonym = Pseudonym.find(params[:id] || params[:pseudonym_id])
  end

  # Only allow a list of trusted parameters through.
  def pseudonym_params
    params.require(:pseudonym).permit(:name, :status)
  end

  def search_params
    params.permit(*PseudonymsController.search_keys)
  end
end
