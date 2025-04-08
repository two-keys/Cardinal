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

    # Rails.logger.debug ad_tier_ids

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

    subs = ActiveSupport::HashWithIndifferentAccess.new(subs)

    customers = Stripe::Customer.list[:data]

    sub_emails = {}

    customers.each do |customer| # rubocop:disable Metrics/BlockLength
      if sub_emails[customer.email].blank? && (subs.key? customer.id)
        sub_emails[customer.email] = {}
        sub_emails[customer.email]['one'] = []
        sub_emails[customer.email]['two'] = []
        sub_emails[customer.email]['three'] = []
        sub_emails[customer.email]['recurring'] = []
      end
      if sub_emails[customer.email]['one'].blank? && (subs.key? customer.id)
        sub_emails[customer.email]['one'] =
          []
      end
      if sub_emails[customer.email]['two'].blank? && (subs.key? customer.id)
        sub_emails[customer.email]['two'] =
          []
      end
      if sub_emails[customer.email]['three'].blank? && (subs.key? customer.id)
        sub_emails[customer.email]['three'] =
          []
      end
      if sub_emails[customer.email]['recurring'].blank? && (subs.key? customer.id)
        sub_emails[customer.email]['recurring'] =
          []
      end

      if subs.key?(customer.id) && subs[customer.id].key?('one')
        sub_emails[customer.email]['one'] << subs[customer.id]['one'].flatten
      end
      if subs.key?(customer.id) && subs[customer.id].key?('two')
        sub_emails[customer.email]['two'] << subs[customer.id]['two'].flatten
      end
      if subs.key?(customer.id) && subs[customer.id].key?('three')
        sub_emails[customer.email]['three'] << subs[customer.id]['three'].flatten
      end
      if subs.key?(customer.id) && subs[customer.id].key?('recurring')
        sub_emails[customer.email]['recurring'] << subs[customer.id]['recurring'].flatten
      end
    end

    sub_emails.keys do |email|
      sub_emails[email]['one'] = sub_emails[email]['one'].flatten if sub_emails[email].key?('one')
      sub_emails[email]['two'] = sub_emails[email]['two'].flatten if sub_emails[email].key?('two')
      sub_emails[email]['three'] = sub_emails[email]['three'].flatten if sub_emails[email].key?('three')
      sub_emails[email]['recurring'] = sub_emails[email]['recurring'].flatten if sub_emails[email].key?('recurring')
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
        sub_emails[user.email][key] = sub_emails[user.email][key].flatten.sort_by { |v| v[:current_period_end] }.reverse
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
