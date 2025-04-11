# frozen_string_literal: true

## Characters controller is inevitably going to have a lot that goes into it
## tag searching, characters, updates, etc
class CharactersController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper
  include AuditableController

  before_action :set_character, only: %i[show edit bump update answer destroy]
  before_action :authenticate_user!

  after_action :track_create, only: :create

  authorize_resource

  include TaggableController
  include SearchableController
  include PseudableController

  def self.search_keys
    %i[before tags nottags ismine]
  end

  # GET /characters
  def index
    query = add_search(Character)

    # we could make this searchable like prompts
    # but that'll take some time to decouple prompt search logic

    # shadowban logic
    unless current_user.shadowbanned? || current_user.admin?
      query = query.joins(:user).where(user: { shadowbanned: false })
    end

    @pagy, @characters = pagy(query.includes(:user, :pseudonym), items: 5)
  end

  # GET /characters/1
  def show; end

  # GET /characters/new
  def new
    @character = Character.new
  end

  # GET /characters/1/edit
  def edit; end

  # POST /characters
  def create
    @character = Character.new(character_params)
    @character.user_id = current_user.id

    added_tags = @character.add_tags(tag_params)

    respond_to do |format|
      if added_tags && @character.save
        format.html { redirect_to character_url(@character), notice: 'Character was successfully created.' }
        format.json { render :show, status: :created, location: @character }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @character.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /characters/1
  def update
    respond_to do |format|
      if @character.update(character_params)
        format.html { redirect_to character_url(@character), notice: 'Character was successfully updated.' }
        format.json { render :show, status: :ok, location: @character }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @character.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /characters/1
  def destroy
    @character.destroy

    respond_to do |format|
      format.html { redirect_to characters_url, notice: 'Character was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def model_class
    'character'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_character
    @character = Character.find(params[:id] || params[:character_id])
  end

  # Only allow a list of trusted parameters through.
  def character_params
    params.require(:character).permit(:name, :description, :color, :status, :default_slots, :pseudonym_id)
  end

  def track_create
    ahoy.track 'Character Created', { user_id: @character.user.id }
  end
end
