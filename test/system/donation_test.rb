# frozen_string_literal: true

require 'application_system_test_case'
require 'minitest/mock'

class DonationTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @chat = chats(:chat_one)
    @chat.users << @user

    @stripe_mock = [
      {
        'items' => {
          'data' => [
            {
              'plan' => {
                'amount' => 10_000
              }
            }
          ]
        }
      }
    ]
  end

  test 'should visit index without login' do
    Stripe::Subscription.stub :list, @stripe_mock do
      visit donation_url
      assert_selector 'h1', text: 'CURRENT GOAL'
    end
  end
end
