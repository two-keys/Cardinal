# frozen_string_literal: true

module Reportable
  extend ActiveSupport::Concern

  included do
    has_many :reports, as: :reportable, dependent: :delete_all
  end
end
