# frozen_string_literal: true

require 'application_system_test_case'

class MessagesTest < ApplicationSystemTestCase
  setup do
    @user = users(:user)
    @chat = chats(:chat_one)
    @chat.users << @user

    @message = messages(:user)
  end

  test 'should create message' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit chat_path(@chat.uuid)
    assert_difference('all(:css, ".message").size') do
      new_frame = find('turbo-frame#message_form_frame', match: :first, wait: 5)
      new_frame.fill_in 'message_content', with: 'Totally definitely new text'
      new_frame.check 'OOC'
      new_frame.click_on('Submit')

      refresh # turboframe wont reload unless we refresh ????
    end

    assert_text 'Totally definitely new text'
  end

  test 'should update message' do
    visit new_user_session_url
    fill_in 'Username', with: @user.username
    fill_in 'Password', with: 123_456
    click_button 'Log in'

    visit chat_path(@chat.uuid)

    container = find('#messages_container')
    container.click_on 'Edit', match: :first

    pending = find("turbo-frame#message_#{@message.id}", wait: 5)
    pending.fill_in 'message_content', with: 'Totally definitely new text'
    pending.check 'OOC' if @message.ooc
    pending.click_on('Submit')

    refresh # turboframe wont reload unless we refresh ????

    assert_text 'edited less than a minute ago'
  end
end
