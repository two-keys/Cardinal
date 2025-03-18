# frozen_string_literal: true

module Entitlementable
  extend ActiveSupport::Concern

  included do
    has_one :entitlement, as: :object, dependent: :destroy
    has_many :user_entitlements, through: :entitlement, dependent: :destroy_async
    has_many :entitlements, as: :object, through: :user_entitlements
    has_many :entitled_users, through: :user_entitlements, source: 'user'

    after_create_commit :generate_entitlement

    def generate_entitlement
      object = self

      new_entitlement = Entitlement.create!(object: self)
      (new_entitlement.users << user) if object.respond_to? :user
    end

    def entitlements_for(user)
      user.entitlements.where(object: self)
    end
  end
end
