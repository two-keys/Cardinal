# frozen_string_literal: true

require 'application_system_test_case'

class PromptsTest < ApplicationSystemTestCase
  setup do
    @user = users(:user)
    @prompt = prompts(:one)
  end

  test 'visiting the index' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit prompts_url
    assert_selector 'h1', text: 'Prompts'
  end

  test 'should create prompt' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit prompts_url
    click_on 'New Prompt'

    fill_in 'Ooc', with: '1234928i383 totally unique prompt ooc'
    fill_in 'Starter', with: '1234929adwjwo totally unique prompt starter'
    click_on 'Submit'

    assert_text 'Prompt was successfully created'
    click_on 'Back'
  end

  test 'should create prompt with tags' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit prompts_url
    click_on 'New Prompt'

    tags_to_look_for = []

    fill_in 'Ooc', with: '1234928i383 totally unique prompt ooc'
    CardinalSettings::Tags.types.each do |tag_type, type_hash|
      next unless type_hash['fill_in']

      type_hash['polarities'].each do |polarity|
        text = "Totally unique #{polarity} #{tag_type} tag"
        tags_to_look_for << text

        input_node = find "input#tags_#{polarity}_#{tag_type}"
        fill_in input_node[:id], with: text
      end
    end
    click_on 'Submit'
    assert_text 'Prompt was successfully created'

    tags_to_look_for.each do |tag_text|
      find 'a', text: tag_text
    end

    click_on 'Back'
  end

  test 'should create prompt with just ooc' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit prompts_url
    click_on 'New Prompt'

    fill_in 'Ooc', with: '1234928i383 totally unique prompt ooc'
    click_on 'Submit'

    assert_text 'Prompt was successfully created'
    click_on 'Back'
  end

  test 'should create prompt with just starter' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit prompts_url
    click_on 'New Prompt'

    fill_in 'Starter', with: '1234929adwjwo totally unique prompt starter'
    click_on 'Submit'

    assert_text 'Prompt was successfully created'
    click_on 'Back'
  end

  test 'should update Prompt starter and ooc' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit prompt_url(@prompt)
    click_on 'Edit this prompt', match: :first

    fill_in 'Ooc', with: @prompt.ooc
    fill_in 'Starter', with: @prompt.starter
    click_on 'Submit', match: :first

    assert_text 'Prompt was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Prompt' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit prompt_url(@prompt)
    click_on 'Destroy this prompt', match: :first

    assert_text 'Prompt was successfully destroyed'
  end
end
