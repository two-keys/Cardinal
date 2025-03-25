class CreateAdTierEntitlements < ActiveRecord::Migration[7.2]
  def up
    Entitlement.find_or_create_by(flag: 'ad-tier', data: 'one')
    Entitlement.find_or_create_by(flag: 'ad-tier', data: 'two')
    Entitlement.find_or_create_by(flag: 'ad-tier', data: 'three')
    Entitlement.find_or_create_by(flag: 'ad-tier', data: 'unlimited')
  end

  def down
    Entitlement.where(flag: 'ad-tier').destroy_all
  end
end
