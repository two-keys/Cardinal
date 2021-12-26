# frozen_string_literal: true

require 'test_helper'

class ThemePreferenceControllerTest < ActionDispatch::IntegrationTest
  Rails.application.config.themes.each do |theme|
    test "should get update with #{theme}" do
      post theme_path, params: { theme: theme }
      assert_response :redirect
    end
  end

  test 'should get update with invalid theme' do
    post theme_path, params: { theme: 'invalid' }
    assert_response :bad_request
  end
end
