# frozen_string_literal: true

module CharacterizedController
  extend ActiveSupport::Concern

  # there's probably a better way to do this but my brain is fried
  included do
    before_action :set_character_options, only: %I[new create edit bump answer update]
  end

  # Used in other controller concerns
  def characterized?
    true
  end

  private

  def set_character_options
    @character_options = Character
                         .where(user: current_user, status: 'posted')
                         .pluck(:name, :id)
                         .unshift(['No Selection', -1])
  end

  def character_params
    params.require(:characters)
  end
end
