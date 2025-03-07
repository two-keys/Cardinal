# frozen_string_literal: true

class Filter < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true

  validates :target_id, uniqueness: { scope: %i[user_id group target_type] }

  validates :group, presence: true
  validates :filter_type, inclusion: { in: %w[Rejection Exception] }
  validates :target_type, inclusion: { in: %w[Tag Prompt Character Pseudonym] }
  validates :priority, numericality: { only_integer: true, greater_than: -999, less_than: 999 }
end
