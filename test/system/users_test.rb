# frozen_string_literal: true

require 'application_system_test_case'

class UsersTest < ApplicationSystemTestCase
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
end
