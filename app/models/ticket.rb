# frozen_string_literal: true

class Ticket < ApplicationRecord
  MAX_PER_DAY = 7

  belongs_to :item, polymorphic: true
  belongs_to :user

  validate :can_spend, on: :create
  validate :owns_item, on: %i[create update]

  def self.remaining(check_user)
    spent_today = Ticket.where(user: check_user, created_at: 1.day.ago..).count

    MAX_PER_DAY - spent_today
  end

  def self.spend(spend_item)
    Ticket.create(user: spend_item.user, item: spend_item)
  end

  private

  def can_spend
    return if Ticket.remaining(user).positive?

    errors.add(:count, 'You\'ve spent all of your tickets.')
  end

  def owns_item
    return if item.user.id == user.id

    errors.add(:user, "You don't own this #{item.class}.")
  end
end
