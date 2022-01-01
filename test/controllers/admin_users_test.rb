# frozen_string_literal: true

require 'test_helper'

class AdminUsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @user = users(:user)
  end

  test 'should get index' do
    sign_in(@admin)
    get admin_users_path
    assert_response :success
  end

  test 'should not get index' do
    sign_in(@user)
    get admin_users_path
    assert_redirected_to root_url
  end

  test 'should get edit' do
    sign_in(@admin)
    get edit_admin_user_path(@user)
    assert_response :success
  end

  test 'should not get edit' do
    sign_in(@user)
    get edit_admin_user_path(@user)
    assert_redirected_to root_url
  end

  test 'should update user' do
    sign_in(@admin)
    patch admin_user_path(@user), params: { user: { verified: false } }
    assert_redirected_to edit_admin_user_path(@user)
  end

  test 'should not update user' do
    sign_in(@user)
    patch admin_user_path(@user), params: { user: { verified: false } }
    assert_redirected_to root_url
  end

  test 'should soft delete user' do
    sign_in(@admin)
    assert_changes('@user.reload.delete_at') do
      delete admin_user_path(@user)
    end
    assert_redirected_to admin_users_path
  end

  test 'should not soft delete user' do
    sign_in(@user)
    assert_no_changes('@user.reload.delete_at') do
      delete admin_user_path(@user)
    end
    assert_redirected_to root_url
  end
end
