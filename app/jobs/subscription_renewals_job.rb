# frozen_string_literal: true

class SubscriptionRenewalsJob < ApplicationJob
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

    all_subs = []

    data = Stripe::Subscription.search(query: 'status: "active"', expand: ['data.customer'])
    has_more = data[:has_more]
    next_page = data[:next_page]
    all_subs << data[:data]

    while has_more && next_page
      data = Stripe::Subscription.search(query: 'status: "active"', expand: ['data.customer'], page: next_page)
      has_more = data[:has_more]
      next_page = data[:next_page]
      all_subs << data[:data]
    end

    subs = {}

    Rails.logger.debug all_subs

    all_subs.flatten.each do |sub|
      subs[sub[:customer][:email]] = {
        one: [],
        two: [],
        three: [],
        recurring: []
      }
    end

    all_subs.flatten.each do |sub| # rubocop:disable Style/CombinableLoops
      sub[:items][:data].each do |item|
        subs[sub[:customer][:email]][:one] << item if ad_tier_ids[:one].include? item[:plan][:id]
        subs[sub[:customer][:email]][:two] << item if ad_tier_ids[:two].include? item[:plan][:id]
        subs[sub[:customer][:email]][:three] << item if ad_tier_ids[:three].include? item[:plan][:id]
        subs[sub[:customer][:email]][:recurring] << item if sub_price_ids.include? item[:plan][:id]
      end
    end

    subs = ActiveSupport::HashWithIndifferentAccess.new(subs)

    subscription_entitlement = Entitlement.find_by!(flag: 'subscription')
    ad_tiers = Entitlement.where(flag: 'ad-tier')
    ad_tier_one = ad_tiers.find_by!(data: 'one')
    ad_tier_two = ad_tiers.find_by!(data: 'two')
    ad_tier_three = ad_tiers.find_by!(data: 'three')

    users = User.where(email: subs.keys)

    users.find_each(batch_size:) do |user| # rubocop:disable Metrics/BlockLength
      subs[user.email].each_key do |key|
        subs[user.email][key] = subs[user.email][key].flatten.sort_by { |v| v[:current_period_end] }.reverse
      end

      if subs[user.email][:one]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: ad_tier_one)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(subs[user.email][:one].first[:current_period_end])
        user_entitlement.save!
      end
      if subs[user.email][:two]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: ad_tier_two)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(subs[user.email][:two].first[:current_period_end])
        user_entitlement.save!
      end
      if subs[user.email][:three]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: ad_tier_three)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(subs[user.email][:three].first[:current_period_end])
        user_entitlement.save!
      end
      if subs[user.email][:recurring]&.count&.positive?
        user_entitlement = UserEntitlement.where(user: user,
                                                 entitlement: subscription_entitlement)
                                          .first_or_initialize { |ue| ue.expires_on = Time.zone.now }
        user_entitlement.expires_on = Time.zone.at(subs[user.email][:recurring].first[:current_period_end])
        user_entitlement.save!
      end
    end
  end
end
