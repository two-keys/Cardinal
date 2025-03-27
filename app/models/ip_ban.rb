# frozen_string_literal: true

class IpBan < ApplicationRecord
  validate :valid_ip

  def valid_ip
    return if addr.present?

    errors.add(:addr, 'must be a valid IPv4/6 Address or Subnet')
  end
end
