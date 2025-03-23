# frozen_string_literal: true

module Legacy
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    connects_to database: { reading: :legacy, writing: :legacy }
  end
end
