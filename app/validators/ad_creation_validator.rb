# frozen_string_literal: true

class AdCreationValidator < ActiveModel::Validator
  def check_existing(variant, user)
    usage = user.ad_usage

    local_errors = []

    local_errors << 'User has no ad-tier entitlements' unless (usage[:entitled]).positive?
    return local_errors unless (usage[:entitled]).positive?

    if usage[variant.to_sym][:used] >= usage[variant.to_sym][:entitled]
      local_errors << "User cannot have more #{variant} ads. Either delete an existing one or grant a new ad-tier entitlement" # rubocop:disable Layout/LineLength
    end

    local_errors
  end

  def validate(record)
    check_existing(record.variant, record.user).each do |error|
      record.errors.add(:base, error)
    end
  end
end
