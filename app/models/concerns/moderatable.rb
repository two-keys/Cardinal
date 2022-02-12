# frozen_string_literal: true

module Moderatable
  extend ActiveSupport::Concern

  # Overrides application_record.rb
  def moderatable
    true
  end
end
