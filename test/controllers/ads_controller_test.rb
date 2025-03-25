# frozen_string_literal: true

require 'test_helper'

class AdsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @user_not_entitled = users(:user_unentitled_for_ads)
  end

  test 'should get index' do
    sign_in(@user)
    get ads_url
    assert_response :success
  end

  test 'unentitled should get index' do
    sign_in(@user_not_entitled)
    get ads_url
    assert_response :success
  end

  test 'should get new' do
    sign_in(@user)
    get new_ad_url
    assert_response :success
  end

  test 'unentitled should not get new' do
    sign_in(@user_not_entitled)
    get new_ad_url
    assert_response :not_found
  end
end
