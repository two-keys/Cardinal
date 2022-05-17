# frozen_string_literal: true

class DonationController < ApplicationController
  def index
    @prices = CardinalSettings::Donation.prices
    @goals = CardinalSettings::Donation.goals
  end

  def create_stripe_session
    session = Stripe::Checkout::Session.create(
      {
        line_items: [{
          price: donation_params[:price],
          quantity: 1
        }],
        mode: donation_params[:mode],
        success_url: donation_url,
        cancel_url: donation_url
      }
    )
    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  private

  # Only allow a list of trusted parameters through.
  def donation_params
    params.permit(:authenticity_token, :price, :mode)
  end
end
