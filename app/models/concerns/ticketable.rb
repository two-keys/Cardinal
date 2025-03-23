# frozen_string_literal: true

module Ticketable
  extend ActiveSupport::Concern

  included do
    after_initialize :set_attr
    after_save :unset_attr
    has_many :tickets, as: :item, dependent: :nullify

    attr_accessor :transfer

    def set_attr
      self.transfer = false unless transfer
    end

    def unset_attr
      self.transfer = nil
    end
  end

  def can_spend
    return if Ticket.remaining(user).positive?

    errors.add(:tickets, 'You don\'t have enough tickets remaining for this.')
  end
end
