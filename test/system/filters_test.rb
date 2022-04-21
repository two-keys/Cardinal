# frozen_string_literal: true

require 'application_system_test_case'

class FiltersTest < ApplicationSystemTestCase
  setup do
    @user = users(:user)
    @filter = filters(:one)
  end

  test 'visiting the index' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit filters_url
    assert_selector 'h1', text: 'Filters'
  end

  test 'should create filter' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit filters_url
    click_on 'New filter'

    select @filter.filter_type, from: 'Filter type'
    fill_in 'Group', with: @filter.group
    fill_in 'Priority', with: @filter.priority

    select 'misc', from: 'Polarity'
    select 'misc', from: 'Tag type'
    fill_in 'Name', with: 'Tag I don\'t Like'

    click_on 'Create Filter'

    assert_text 'Filter was successfully created'
    click_on 'Back'
  end

  test 'should update Filter' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit filter_url(@filter)
    click_on 'Edit this filter', match: :first

    select @filter.filter_type, from: 'Filter type'
    fill_in 'Group', with: @filter.group
    fill_in 'Priority', with: @filter.priority

    select 'misc', from: 'Polarity'
    select 'misc', from: 'Tag type'
    fill_in 'Name', with: 'Tag I don\'t Like'

    click_on 'Update Filter'

    assert_text 'Filter was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Filter' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit filter_url(@filter)
    click_on 'Destroy this filter', match: :first

    assert_text 'Filter was successfully destroyed'
  end
end
