# frozen_string_literal: true

module PseudableController
  extend ActiveSupport::Concern

  # there's probably a better way to do this but my brain is fried
  included do
    before_action :set_pseudonym_options, only: %I[new create edit bump answer update]
  end

  # Used in other controller concerns
  def pseudable?
    true
  end

  private

  def set_pseudonym_options
    @pseudonym_options = Pseudonym
                         .where(user: current_user, status: 'posted')
                         .pluck(:name, :id)
                         .unshift(['No Selection', ''])
  end

  def pseudonym_params
    params.require(:pseudonyms)
  end
end
