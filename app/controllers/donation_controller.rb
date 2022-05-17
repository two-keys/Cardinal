# frozen_string_literal: true

class DonationController < ApplicationController
  def index
    @prices = CardinalSettings::Donation.prices
    @goals = CardinalSettings::Donation.goals
  end
end
