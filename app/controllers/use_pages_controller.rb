# frozen_string_literal: true

class UsePagesController < ApplicationController
  before_action :set_use_page, only: %i[show edit update destroy]

  load_and_authorize_resource

  # GET /use or /use.json
  def index
    respond_to do |format|
      format.html do
        redirect_to use_page_path('index'), status: :see_other
      end
      format.json { head :no_content }
    end
  end

  # GET /use_pages/1 or /use_pages/1.json
  def show
    @use_pages = UsePage.all
  end

  # GET /use_pages/new
  def new
    @use_page = UsePage.new(order: UsePage.count)
  end

  # GET /use_pages/1/edit
  def edit; end

  # POST /use_pages or /use_pages.json
  def create
    @use_page = UsePage.new(use_page_params)

    respond_to do |format|
      if @use_page.save
        format.html { redirect_to @use_page, notice: 'Site use page was successfully created.' }
        format.json { render :show, status: :created, location: @use_page }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @use_page.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /use_pages/1 or /use_pages/1.json
  def update
    respond_to do |format|
      if @use_page.update(use_page_params)
        format.html { redirect_to @use_page, notice: 'Site use page was successfully updated.' }
        format.json { render :show, status: :ok, location: @use_page }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @use_page.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /use_pages/1 or /use_pages/1.json
  def destroy
    @use_page.destroy!

    respond_to do |format|
      format.html do
        redirect_to use_pages_path, status: :see_other, notice: 'Site use page was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_use_page
    @use_page = UsePage.find_by(title: params[:id])
    return unless @use_page.nil?

    raise ActiveRecord::RecordNotFound
  end

  # Only allow a list of trusted parameters through.
  def use_page_params
    params.require(:use_page).permit(:title, :content, :order)
  end
end
