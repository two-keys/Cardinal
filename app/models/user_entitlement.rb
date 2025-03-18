# frozen_string_literal: true

class UserEntitlement < ApplicationRecord
  belongs_to :user
  belongs_to :entitlement

  validates :user_id, uniqueness: { scope: :entitlement_id }
end
