# frozen_string_literal: true

module HideableController
  extend ActiveSupport::Concern

  # there's probably a better way to do this but my brain is fried
  included do
    before_action :set_hideable, only: %i[hide]
  end

  # POST /prompts/1/hide
  def hide
    new_filter = Filter.create(
      user: current_user, target: @hideable,
      group: 'simple',
      filter_type: 'Rejection', priority: 0
    )

    respond_to do |format|
      if new_filter.save
        format.html { redirect_to url_for(new_filter), notice: 'Filter was successfully created.' }
        format.json { render :show, status: :ok, location: new_filter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: new_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_hideable
    case self.class.name
    when 'TagsController'
      set_tag
    when 'PromptsController'
      set_prompt
    when 'CharactersController'
      set_character
    when 'PseudonymsController'
      set_pseudonym
    else
      logger.debug "my case statement name is '#{self.class.name}'"
    end
    @hideable = [@tag, @prompt, @character, @pseudonym].find(&:present?)
  end
end
