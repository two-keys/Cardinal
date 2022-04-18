# frozen_string_literal: true

class Filter < ApplicationRecord
  belongs_to :user
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: %i[user_id group] }

  validates :group, presence: true
  validates :filter_type, inclusion: { in: %w[Rejection Exception] }
  validates :priority, numericality: { only_integer: true, greater_than: -999, less_than: 999 }
end
