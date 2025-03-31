class CreateSubscriptionEntitlement < ActiveRecord::Migration[7.2]
  def up
    Entitlement.find_or_create_by(flag: 'subscription')
  end
  def down
    Entitlement.where(flag: 'subscription').destroy_all
  end
end
