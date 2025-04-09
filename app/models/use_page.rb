# frozen_string_literal: true

class UsePage < ApplicationRecord
  validates :title, presence: true, uniqueness: true

  default_scope { order(order: :asc) }

  def to_param
    title.parameterize
  end
end
