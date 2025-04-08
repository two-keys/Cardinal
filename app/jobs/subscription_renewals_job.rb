# frozen_string_literal: true

class SubscriptionRenewalsJob < ApplicationJob # rubocop:disable Metrics/ClassLength
  queue_as :default

  def perform # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    batch_size = 100

    sub_price_ids = CardinalSettings::Donation.prices.pluck('monthly')

    ad_tier_ids = {
      one: [],
      two: [],
      three: []
    }

    CardinalSettings::Ads.tier_one.each do |skew|
      ad_tier_ids[:one] << skew.second['id']
    end

    CardinalSettings::Ads.tier_two.each do |skew|
      ad_tier_ids[:two] << skew.second['id']
    end

    CardinalSettings::Ads.tier_three.each do |skew|
      ad_tier_ids[:three] << skew.second['id']
    end

    all_subs = Stripe::Subscription.search(query: 'status: "active"')[:data]

    subs = {}

    all_subs.map do |item| # rubocop:disable Metrics/BlockLength
      item[:items][:data].each do |obj| # rubocop:disable Metrics/BlockLength
        if subs[item[:customer]].blank? && ad_tier_ids[:one].include?(obj[:plan][:id])
          subs[item[:customer]] =
            {}
        end
        if subs[item[:customer]].blank? && ad_tier_ids[:two].include?(obj[:plan][:id])
          subs[item[:customer]] =
            {}
        end
        if subs[item[:customer]].blank? && ad_tier_ids[:three].include?(obj[:plan][:id])
          subs[item[:customer]] =
            {}
        end
        if subs[item[:customer]].blank? && sub_price_ids.include?(obj[:plan][:id])
          subs[item[:customer]] =
            {}
        end
        if subs[item[:customer]][:one].blank? && ad_tier_ids[:one].include?(obj[:plan][:id])
          subs[item[:customer]][:one] =
            []
        end
        if subs[item[:customer]][:two].blank? && ad_tier_ids[:two].include?(obj[:plan][:id])
          subs[item[:customer]][:two] =
            []
        end
        if subs[item[:customer]][:three].blank? && ad_tier_ids[:three].include?(obj[:plan][:id])
          subs[item[:customer]][:three] =
            []
        end
        if subs[item[:customer]][:recurring].blank? && sub_price_ids.include?(obj[:plan][:id])
          subs[item[:customer]][:recurring] =
            []
        end
        subs[item[:customer]][:one] << obj if ad_tier_ids[:one].include? obj[:plan][:id]
        subs[item[:customer]][:two] << obj if ad_tier_ids[:two].include? obj[:plan][:id]
        subs[item[:customer]][:three] << obj if ad_tier_ids[:three].include? obj[:plan][:id]
        subs[item[:customer]][:recurring] << obj if sub_price_ids.include? obj[:plan][:id]
      end
    end

    customers = Stripe::Customer.list[:data]

    sub_emails = {}

    customers.each do |customer|
      sub_emails[customer.email] = subs[customer.id] if subs.key? customer.id
    end

    sub_emails = ActiveSupport::HashWithIndifferentAccess.new(sub_emails)

    subscription_entitlement = Entitlement.find_by!(flag: 'subscription')
    ad_tiers = Entitlement.where(flag: 'ad-tier')
    ad_tier_one = ad_tiers.find_by!(data: 'one')
    ad_tier_two = ad_tiers.find_by!(data: 'two')
    ad_tier_three = ad_tiers.find_by!(data: 'three')

    users = User.where(email: sub_emails.keys)

    users.find_each(batch_size:) do |user| # rubocop:disable Metrics/BlockLength
      sub_emails[user.email].each_key do |key|
        sub_emails[user.email][key] = sub_emails[user.email][key].sort_by { |v| v[:current_period_end] }.reverse
      end

      if sub_emails[user.email][:one]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: ad_tier_one)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(sub_emails[user.email][:one].first[:current_period_end])
        user_entitlement.save!
      end
      if sub_emails[user.email][:two]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: ad_tier_two)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(sub_emails[user.email][:two].first[:current_period_end])
        user_entitlement.save!
      end
      if sub_emails[user.email][:three]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: ad_tier_three)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(sub_emails[user.email][:three].first[:current_period_end])
        user_entitlement.save!
      end
      if sub_emails[user.email][:recurring]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: subscription_entitlement)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(sub_emails[user.email][:recurring].first[:current_period_end])
        user_entitlement.save!
      end
    end
  end
end
