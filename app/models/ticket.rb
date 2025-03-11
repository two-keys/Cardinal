# frozen_string_literal: true

class Ticket < ApplicationRecord
  MAX_PER_DAY = 7

  belongs_to :item, polymorphic: true
  belongs_to :user

  validates :item_type, inclusion: { in: %w[Prompt Character Pseudonym] }, allow_nil: true

  validate :can_spend, on: :create
  validate :owns_item, on: %i[create update]

  def self.remaining(check_user)
    spent_today = Ticket.where(user: check_user, created_at: 1.day.ago..).count

    MAX_PER_DAY - spent_today
  end

  def self.spend(spend_item)
    ahoy = Ahoy.instance
    Ticket.create!(user: spend_item.user, item: spend_item)

    return unless ahoy

    ahoy.track 'Ticket Created',
               { user_id: spend_item.user.id, item_id: spend_item.id, item_type: spend_item.item_type }
  end

  def destroyable?
    diff_in_seconds = Time.zone.at(DateTime.now) - created_at
    diff_in_seconds += 1.second # a surprise tool to help us later
    seconds_in_a_day = 24 * 60 * 60

    diff_in_seconds / seconds_in_a_day >= 1
  end

  def destroy!
    unless destroyable?
      errors.add(:destroy, 'Cannot destroy ticket until 24 hours have passed')
      return false
    end

    super
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
