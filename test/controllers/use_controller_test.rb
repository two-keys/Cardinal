# frozen_string_literal: true

require 'test_helper'

class UseControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @user2 = users(:user_two)
  end

  test 'should get index' do
    get use_page_path
    assert_response :success
  end

  test 'should get each page in SETTINGS_HASH' do
    CardinalSettings::Use.pages.each do |key, _page_hash|
      # sending a get response to the use controller
      get use_page_path key
      assert_response :success
    end
  end

  test 'should redirect page not in SETTINGS_HASH' do
    get use_page_path 'not_in_use_page_path'
    assert_redirected_to use_page_path
  end

  test 'should get json array for each page with the entries key in SETTINGS_HASH' do
    CardinalSettings::Use.pages.each do |key, page_hash|
      next unless page_hash.key?('entries')

      get use_page_path(key, format: :json)
      assert_response :success
      assert_equal 'application/json', @response.media_type
    end
  end
end
