# frozen_string_literal: true

class Entitlement < ApplicationRecord
  include Auditable

  has_many :user_entitlements, dependent: :destroy_async
  has_many :users, through: :user_entitlements
  belongs_to :object, polymorphic: true, optional: true

  validates :object_id, uniqueness: { scope: %i[object_type flag data], allow_blank: true }
  validate :any_present?

  def any_present?
    return false unless %w[flag object_id object_type].all? { |attr| self[attr].blank? || self[attr].nil? }

    errors.add :base, 'Must include either a flag or an object'
  end
end
