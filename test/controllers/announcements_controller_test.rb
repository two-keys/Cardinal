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
    assert_raise CanCan::AccessDenied do
      get new_announcement_url
    end
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
      assert_raise CanCan::AccessDenied do
        post announcements_url, params: { announcement: { content: @announcement.content, title: @announcement.title } }
      end
    end
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
    assert_raise CanCan::AccessDenied do
      get edit_announcement_url(@announcement)
    end
  end

  test 'should update announcement' do
    sign_in(@admin)
    patch announcement_url(@announcement),
          params: { announcement: { content: @announcement.content, title: @announcement.title } }
    assert_redirected_to announcement_url(@announcement)
  end

  test 'should not update announcement' do
    sign_in(@user)
    assert_raise CanCan::AccessDenied do
      patch announcement_url(@announcement),
            params: { announcement: { content: @announcement.content, title: @announcement.title } }
    end
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
      assert_raise CanCan::AccessDenied do
        delete announcement_url(@announcement)
      end
    end
  end
end
