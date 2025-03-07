# frozen_string_literal: true

require 'test_helper'

class FiltersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @user2 = users(:user_two)
    @filter = filters(:one)
  end

  test 'should get index' do
    sign_in(@user)

    get filters_url
    assert_response :success
  end

  test 'should get new' do
    sign_in(@user)

    get new_filter_url
    assert_response :success
  end

  test 'should create filter' do
    sign_in(@user)

    assert_difference('Filter.count') do
      post filters_url, params: {
        filter: { filter_type: 'Rejection', group: 'default', priority: 0 },
        tag: { polarity: 'misc', tag_type: 'misc', name: 'Tag I don\'t Like' }
      }
    end

    assert_redirected_to filter_url(Filter.last)
  end

  test 'should show filter' do
    sign_in(@user)

    get filter_url(@filter)
    assert_response :success
  end

  test 'should not show filter user doesnt own' do
    sign_in(@user2)

    get filter_url(@filter)
    assert_response :missing
  end

  test 'should get edit' do
    sign_in(@user)

    get edit_filter_url(@filter)
    assert_response :success
  end

  test 'should not get edit for filter user doesnt own' do
    sign_in(@user2)

    get edit_filter_url(@filter)
    assert_response :missing
  end

  test 'should update filter' do
    sign_in(@user)

    patch filter_url(@filter), params: {
      filter: { filter_type: @filter.filter_type, group: @filter.group, priority: @filter.priority },
      tag: { polarity: 'misc', tag_type: 'misc', name: 'Tag I don\'t Like' }
    }
    assert_redirected_to filter_url(@filter)
  end

  test 'should not update filter user doesn\'t own' do
    sign_in(@user2)

    patch filter_url(@filter), params: {
      filter: { filter_type: @filter.filter_type, group: @filter.group, priority: @filter.priority },
      tag: { polarity: 'misc', tag_type: 'misc', name: 'Tag I don\'t Like' }
    }

    assert_response :missing
  end

  test 'should destroy filter' do
    sign_in(@user)

    assert_difference('Filter.count', -1) do
      delete filter_url(@filter)
    end

    assert_redirected_to filters_url
  end

  test 'should not destroy filter user doesn\'t own' do
    sign_in(@user2)

    assert_no_difference 'Filter.count' do
      delete filter_url(@filter)
    end

    assert_response :missing
  end

  test 'should create filter someone else has' do
    sign_in(@user2)
    tag = @filter.target

    assert_difference('Filter.count') do
      post filters_url, params: {
        filter: { filter_type: @filter.filter_type, group: 'default', priority: @filter.priority },
        tag: { polarity: tag.polarity, tag_type: tag.tag_type, name: tag.name }
      }
    end

    assert_redirected_to filter_url(Filter.find_by(user: @user2, target: tag))
  end
end
