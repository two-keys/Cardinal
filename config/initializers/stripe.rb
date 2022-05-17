# frozen_string_literal: true

# Set your secret key. Remember to switch to your live secret key in production.
# See your keys here: https://dashboard.stripe.com/apikeys
Stripe.api_key = ENV.fetch('STRIPE_API_KEY', nil)
