# frozen_string_literal: true

class ThemesController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :authenticate_user!
  before_action :set_theme, only: %i[show edit update destroy apply]

  # GET /themes or /themes.json
  def index
    @themes = Theme.available(current_user)
    Rails.logger.debug @themes
  end

  # GET /themes/1 or /themes/1.json
  def show; end

  # GET /themes/new
  def new
    @theme = Theme.new
    @theme.css = default_content
  end

  # GET /themes/1/edit
  def edit; end

  # POST /themes or /themes.json
  def create
    @theme = Theme.new(theme_params)
    @theme.user = current_user

    respond_to do |format|
      if @theme.save
        format.html { redirect_to @theme, notice: 'Theme was successfully created.' }
        format.json { render :show, status: :created, location: @theme }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /themes/1 or /themes/1.json
  def update
    respond_to do |format|
      if @theme.update(theme_params)
        format.html { redirect_to edit_theme_path(@theme), notice: 'Theme was successfully updated.' }
        format.json { render :show, status: :ok, location: @theme }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /themes/1 or /themes/1.json
  def destroy
    @theme.destroy!

    respond_to do |format|
      format.html { redirect_to themes_path, status: :see_other, notice: 'Theme was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /themes/1/apply or /themes/1/apply.json
  def apply
    respond_to do |format|
      if current_user.update(theme: @theme)
        format.html { redirect_to themes_url, notice: 'Theme was successfully applied.' }
        format.json { render :show, status: :ok, location: @theme }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @theme.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def default_content
    <<~CSS
      .light-custom {
        --main-bg-color: #d6d6d6;
        --main-text-color: rgb(44, 44, 44);
        --header-bg-color: #9c9c9c;
        --card-bg-color: #bebebe;
        --card-text-color: rgb(61, 61, 61);
        --card-bg-color-secondary: rgb(209, 209, 209);
        --card-text-color-secondary: rgb(71, 71, 71);
        --card-textarea-bg-color: rgb(228, 228, 228);
        --card-textarea-text-color: #333;

        --tag-generic: #888;
        --tag-generic-text: #000;

        --tag-genre: var(--tag-generic);
        --tag-genre-text: var(--tag-generic-text);
        --tag-gender: var(--tag-generic);
        --tag-gender-text: var(--tag-generic-text);
        --tag-character: var(--tag-generic);
        --tag-character-text: var(--tag-generic-text);
        --tag-characteristic: var(--tag-generic);
        --tag-characteristic-text: var(--tag-generic-text);
        --tag-setting: var(--tag-generic);
        --tag-setting-text: var(--tag-generic-text);
        --tag-post-length: var(--tag-generic);
        --tag-post-length-text: var(--tag-generic-text);
        --tag-rp-length: var(--tag-generic);
        --tag-rp-length-text: var(--tag-generic-text);
        --tag-character-pref: var(--tag-generic);
        --tag-character-pref-text: var(--tag-generic-text);
        --tag-plot: var(--tag-generic);
        --tag-plot-text: var(--tag-generic-text);
        --tag-theme: var(--tag-generic);
        --tag-theme-text: var(--tag-generic-text);
        --tag-detail: var(--tag-generic);
        --tag-detail-text: var(--tag-generic-text);

        --tag-fandom: #424242;
        --tag-fandom-text: #fff;

        --tag-light-warning: var(--ended-color);
        --tag-light-warning-text: #fff;

        --tag-heavy-warning: var(--ended-color);
        --tag-heavy-warning-text: #fff;

        --ongoing-color: grey;
        --unread-color: cornflowerblue;
        --unanswered-color: #9acd32;
        --ended-color: firebrick;

        --nav-bg-color: var(--card-bg-color);
      }
      .dark-custom {
        --main-bg-color: #d6d6d6;
        --main-text-color: rgb(44, 44, 44);
        --header-bg-color: #9c9c9c;
        --card-bg-color: #bebebe;
        --card-text-color: rgb(61, 61, 61);
        --card-bg-color-secondary: rgb(209, 209, 209);
        --card-text-color-secondary: rgb(71, 71, 71);
        --card-textarea-bg-color: rgb(228, 228, 228);
        --card-textarea-text-color: #333;

        --tag-generic: #888;
        --tag-generic-text: #000;

        --tag-genre: var(--tag-generic);
        --tag-genre-text: var(--tag-generic-text);
        --tag-gender: var(--tag-generic);
        --tag-gender-text: var(--tag-generic-text);
        --tag-character: var(--tag-generic);
        --tag-character-text: var(--tag-generic-text);
        --tag-characteristic: var(--tag-generic);
        --tag-characteristic-text: var(--tag-generic-text);
        --tag-setting: var(--tag-generic);
        --tag-setting-text: var(--tag-generic-text);
        --tag-post-length: var(--tag-generic);
        --tag-post-length-text: var(--tag-generic-text);
        --tag-rp-length: var(--tag-generic);
        --tag-rp-length-text: var(--tag-generic-text);
        --tag-character-pref: var(--tag-generic);
        --tag-character-pref-text: var(--tag-generic-text);
        --tag-plot: var(--tag-generic);
        --tag-plot-text: var(--tag-generic-text);
        --tag-theme: var(--tag-generic);
        --tag-theme-text: var(--tag-generic-text);
        --tag-detail: var(--tag-generic);
        --tag-detail-text: var(--tag-generic-text);

        --tag-fandom: #424242;
        --tag-fandom-text: #fff;

        --tag-light-warning: var(--ended-color);
        --tag-light-warning-text: #fff;

        --tag-heavy-warning: var(--ended-color);
        --tag-heavy-warning-text: #fff;

        --ongoing-color: grey;
        --unread-color: cornflowerblue;
        --unanswered-color: #9acd32;
        --ended-color: firebrick;

        --nav-bg-color: var(--card-bg-color);
      }
    CSS
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_theme
    @theme = Theme.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def theme_params
    params.require(:theme).permit(:title, :public, :system, :css)
  end
end
