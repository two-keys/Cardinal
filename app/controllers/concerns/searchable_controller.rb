# frozen_string_literal: true

module SearchableController
  extend ActiveSupport::Concern

  # there's probably a better way to do this but my brain is fried
  included do
    before_action :set_searchable, only: %i[update_tags]
  end

  # Used in other controller concerns
  def searchable?
    true
  end

  # @param obj_class [ApplicationRecord]
  # @param query This can be the object in question or an instance of ActiveRecord::Relation
  # @return [ActiveRecord::Relation]
  def add_search(obj_class)
    SearchHelper.add_search(
      obj_class,
      current_user,
      current_ability,
      search_params,
      characterized?
    )
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

    new_params = search_params.merge(
      tags: "#{previous_tag_param_string}#{tag_strings.join(',')}"
    ).to_hash # to_hash removes unpermitted keys
    new_url = url_for(
      action: :index,
      controller: self.class.name.downcase.chomp('controller'),
      **new_params
    ).to_s

    redirect_to(
      new_url
    )
  end

  # PATCH/PUT /prompts/1/tags
  def update_tags
    added_tags = @searchable.add_tags(tag_params)
    added_characters = @searchable.add_characters(character_params) if characterized?

    respond_to do |format|
      if added_tags && (characterized? == false || added_characters) && @searchable.save
        format.html { redirect_to url_for(@searchable), notice: 'Tags were successfully updated.' }
        format.json { render :show, status: :ok, location: @searchable }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @searchable.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def tag_params
    params.require(:tags).permit(**CardinalSettings::Tags.allowed_type_params)
  end

  def search_params
    params.permit(:before, :tags, :nottags)
  end

  def set_searchable
    case self.class.name
    when 'PromptsController'
      set_prompt
    when 'CharactersController'
      set_character
    else
      logger.debug "my case statement name is '#{self.class.name}'"
    end
    @searchable = [@prompt, @character].find(&:present?)
  end
end
