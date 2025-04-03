# frozen_string_literal: true

class Filter < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true
  # belongs_to :tag, -> { where(filters: { target_type: 'Tag' }) }, foreign_key: 'target_id', inverse_of: :filters

  validates :target_id, uniqueness: { scope: %i[user_id group target_type] }

  validates :group, presence: true
  validates :filter_type, inclusion: { in: %w[Rejection Exception] }
  validates :target_type, inclusion: { in: %w[Tag Prompt Character Pseudonym] }
  validates :priority, numericality: { only_integer: true, greater_than: -999, less_than: 999 }

  # Should really only be called from controller
  # @param tag_params [Object] Permitted tag_params
  def self.from_tag_params(tag_params, user, variant)
    filter_type = variant == 'whitelist' ? 'Exception' : 'Rejection'
    tagset = Tag.from_tag_params(tag_params)

    Filter.where(user:, filter_type:, group: 'simple').destroy_all

    tagset.each do |tag|
      Filter.create!(user:, target: tag, filter_type:, priority: 0, group: 'simple')
    end
  end
end
