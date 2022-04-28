# frozen_string_literal: true

require 'application_system_test_case'

class AnnouncementsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @announcement = announcements(:one)

    sign_in(@admin)
  end

  test 'visiting the index' do
    visit announcements_url
    assert_selector 'h1', text: 'News'
  end

  test 'should create announcement' do
    visit announcements_url
    click_on 'New announcement'

    fill_in 'Content', with: @announcement.content
    fill_in 'Title', with: @announcement.title
    click_on 'Create Announcement'

    assert_text 'Announcement was successfully created'
    click_on 'Back'
  end

  test 'should update Announcement' do
    visit announcement_url(@announcement)
    click_on 'Edit this announcement', match: :first

    fill_in 'Content', with: @announcement.content
    fill_in 'Title', with: @announcement.title
    click_on 'Update Announcement'

    assert_text 'Announcement was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Announcement' do
    visit announcement_url(@announcement)
    click_on 'Destroy this announcement', match: :first

    assert_text 'Announcement was successfully destroyed'
  end
end
