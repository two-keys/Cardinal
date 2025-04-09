# frozen_string_literal: true

require 'test_helper'

class UsePagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @admin = users(:admin)
    @index = use_pages(:index)
    @other = use_pages(:other)
  end

  test 'should redirect to index' do
    sign_in(@user)
    get use_pages_url
    assert_response :see_other
  end

  test 'should get page' do
    sign_in(@user)
    get use_page_url('other')
    assert_response :ok
  end

  test 'unauthorized user should not create page' do
    sign_in(@user)

    assert_no_difference('UsePage.count') do
      post use_pages_url, params: { use_page: { title: 'test', content: 'test' } }
    end

    assert_response :missing
  end

  test 'unauthorized user should not update page' do
    sign_in(@user)

    patch use_page_url(@other), params: { use_page: { title: 'test', content: 'test' } }

    assert_response :missing
  end

  test 'unauthorized user should not destroy page' do
    sign_in(@user)

    assert_no_difference 'UsePage.count' do
      delete use_page_url(@other)
    end

    assert_response :missing
  end

  test 'admin user should create page' do
    sign_in(@admin)

    assert_difference('UsePage.count') do
      post use_pages_url, params: { use_page: { title: 'test', content: 'test' } }
    end

    assert_response :found
  end

  test 'admin user should update page' do
    sign_in(@admin)

    patch use_page_url(@other), params: { use_page: { title: 'test', content: 'test' } }

    assert_response :found
  end

  test 'admin user should destroy page' do
    sign_in(@admin)

    assert_difference('UsePage.count', -1) do
      delete use_page_url(@other)
    end

    assert_redirected_to use_pages_url
  end

  test 'admin user should not destroy index page' do
    sign_in(@admin)

    assert_no_difference 'UsePage.count' do
      delete use_page_url(@index)
    end

    assert_response :missing
  end
end
