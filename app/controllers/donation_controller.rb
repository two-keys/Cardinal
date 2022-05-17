# frozen_string_literal: true

class DonationController < ApplicationController
  def index
    @goals = CardinalSettings::Donation.goals
  end
end
