require "test_helper"

class ThemePreferenceControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get theme_preference_index_url
    assert_response :success
  end
end
