# frozen_string_literal: true

require 'test_helper'

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @announcement = announcements(:one)
    @admin = users(:admin)
    @user = users(:user)
  end

  test 'should get index' do
    get announcements_url
    assert_response :success
  end

  test 'should get new' do
    sign_in(@admin)
    get new_announcement_url
    assert_response :success
  end

  test 'should not get new' do
    sign_in(@user)
    get new_announcement_url
    assert_response :missing
  end

  test 'should create announcement' do
    sign_in(@admin)
    assert_difference('Announcement.count') do
      post announcements_url, params: { announcement: { content: @announcement.content, title: @announcement.title } }
    end

    assert_redirected_to announcement_url(Announcement.first)
  end

  test 'should not create announcement' do
    sign_in(@user)
    assert_no_difference('Announcement.count') do
      post announcements_url, params: { announcement: { content: @announcement.content, title: @announcement.title } }
    end

    assert_response :missing
  end

  test 'should show announcement' do
    get announcement_url(@announcement)
    assert_response :success
  end

  test 'should get edit' do
    sign_in(@admin)
    get edit_announcement_url(@announcement)
    assert_response :success
  end

  test 'should not get edit' do
    sign_in(@user)
    get edit_announcement_url(@announcement)
    assert_response :missing
  end

  test 'should update announcement' do
    sign_in(@admin)
    patch announcement_url(@announcement),
          params: { announcement: { content: @announcement.content, title: @announcement.title } }
    assert_redirected_to announcement_url(@announcement)
  end

  test 'should not update announcement' do
    sign_in(@user)
    patch announcement_url(@announcement),
          params: { announcement: { content: @announcement.content, title: @announcement.title } }

    assert_response :missing
  end

  test 'should destroy announcement' do
    sign_in(@admin)
    assert_difference('Announcement.count', -1) do
      delete announcement_url(@announcement)
    end

    assert_redirected_to announcements_url
  end

  test 'should not destroy announcement' do
    sign_in(@user)
    assert_no_difference('Announcement.count') do
      delete announcement_url(@announcement)
    end

    assert_response :missing
  end

  test 'should get announcement history as admin' do
    sign_in(@admin)
    get history_announcement_url(@announcement)
    assert_response :ok
  end

  test 'should not get character history as non-admin' do
    sign_in(@user)
    get history_announcement_url(@announcement)
    assert_response :missing
  end
end
