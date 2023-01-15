# frozen_string_literal: true

require 'application_system_test_case'

class ConnectCodesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @chat = chats(:chat_one)
    @chat2 = chats(:chat_two)
    @user = users(:user)
    @user2 = users(:user_two)
    @user3 = users(:user_three)

    @connect_code = connect_codes(:chat_one)
    @connect_code2 = connect_codes(:chat_two)

    @chat.chat_users << ChatUser.new(user: @user, role: ChatUser.roles[:chat_admin]) # prompt owner
    @chat.chat_users << ChatUser.new(user: @user2)
  end

  test 'should see connect code form' do
    sign_in(@user)

    visit edit_chat_path @chat.uuid
    assert_text 'Connect Code'
  end

  test 'should update connect code' do
    sign_in(@user)

    visit edit_chat_path @chat.uuid

    fill_in 'Remaining uses', with: 0
    click_on 'Save', match: :first

    assert_text 'Code was successfully updated'
  end
end
