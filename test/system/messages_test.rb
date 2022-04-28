# frozen_string_literal: true

require 'application_system_test_case'

class MessagesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @chat = chats(:chat_one)
    @chat.users << @user

    @message = messages(:user)

    sign_in(@user)
  end

  test 'should create message' do
    visit chat_path(@chat.uuid)

    new_frame = find('turbo-frame#message_form_frame', match: :first, wait: 5)
    new_frame.fill_in 'message_content', with: 'Totally definitely new text'
    new_frame.check 'OOC'
    new_frame.click_on('Submit')

    refresh # turboframe wont reload unless we refresh ????

    assert_text 'Totally definitely new text'
  end

  test 'should update message' do
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
