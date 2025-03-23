# frozen_string_literal: true

module Ticketable
  extend ActiveSupport::Concern

  included do
    has_many :tickets, as: :item, dependent: :nullify
  end

  def can_spend
    return if Ticket.remaining(user).positive?

    errors.add(:tickets, 'You don\'t have enough tickets remaining for this.')
  end
end
