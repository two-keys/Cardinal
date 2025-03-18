# frozen_string_literal: true

require 'application_system_test_case'

class UsersTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @unbanned = users(:user)
    @banned = users(:user_banned)
    @deleted = users(:user_deleted)
    @banned_deleted = users(:user_banned_deleted)
    @expired = users(:user_ban_expired)
  end

  test 'unbanned and undeleted user can log in' do
    visit new_user_session_url
    fill_in 'Username', with: @unbanned.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    assert_text 'Signed in successfully.'
  end

  test 'banned user cannot log in' do
    visit new_user_session_url
    fill_in 'Username', with: @banned.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    assert_text 'Test Ban'
  end

  test 'deleted user cannot log in' do
    visit new_user_session_url
    fill_in 'Username', with: @deleted.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    assert_text 'This account is pending for deletion.'
  end

  test 'deleted and banned user will get deleted message' do
    visit new_user_session_url
    fill_in 'Username', with: @banned_deleted.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    assert_text 'This account is pending for deletion.'
  end

  test 'expired ban can log in' do
    visit new_user_session_url
    fill_in 'Username', with: @expired.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    assert_text 'Signed in successfully.'
  end

  test 'guest can register' do
    visit new_user_registration_path
    fill_in 'Email', with: 'nonexistent@example.com'
    fill_in 'Username', with: 'nonexistent'
    fill_in 'Password', with: 123_456
    fill_in 'Password confirmation', with: 123_456
    assert_changes('UserEntitlement.count', 1) do
      click_button 'Sign up'
    end

    assert_text 'Welcome! You have signed up successfully.'
  end

  test 'user can reach edit profile' do
    sign_in(@unbanned)
    visit edit_user_registration_path

    assert_text 'Edit User'
  end
end
