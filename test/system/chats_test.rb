# frozen_string_literal: true

require 'application_system_test_case'

class ChatsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @chat = chats(:chat_one)
    @chat.users << @user

    sign_in(@user)
  end

  test 'visiting the index' do
    visit chats_url
    assert_selector 'h1', text: 'Chats'
  end

  # TODO: Move this to a prompts system test once they're finished?
  #  test 'should create chat' do
  #    visit chats_url
  #    click_on 'New chat'
  #
  #    click_on 'Create Chat'
  #
  #    assert_text 'Chat was successfully created'
  #    click_on 'Back'
  #  end

  test 'should update Chat' do
    visit chat_path(@chat.uuid)
    find('.chat-actions').click_on 'Edit', match: :first

    click_on 'Update Chat'

    assert_text 'Chat was successfully updated'
  end

  test 'should destroy Chat' do
    visit chat_path(@chat.uuid)
    find('.chat-actions').click_on 'Delete', match: :first

    assert_text 'Chat was successfully destroyed'
  end
end
