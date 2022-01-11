# frozen_string_literal: true

require 'test_helper'

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @message = messages(:user)
    @user = users(:user)
    @user2 = users(:user_two)
    @user3 = users(:user_three)
    @chat = chats(:chat_one)
    @chat.users << @user
    @chat.users << @user3
  end

  test 'should create message' do
    sign_in(@user)
    assert_difference('Message.count') do
      post messages_url, params: { message: { content: 'test', ooc: false, chat_id: @chat.id } }
    end

    assert :success
  end

  test 'unauthorized user should not create message' do
    sign_in(@user2)
    assert_no_difference('Message.count') do
      post messages_url, params: { message: { content: 'test', ooc: false, chat_id: @chat.id } }
    end

    assert_redirected_to root_url
  end

  test 'user cannot create message as another user' do
    sign_in(@user3)
    assert_no_difference('Message.where(user_id: @user.id).count') do
      post messages_url, params: { message: { content: 'test', ooc: false, user_id: @user.id, chat_id: @chat.id } }
    end
  end

  test 'not logged in should not create message' do
    assert_no_difference('Message.count') do
      post messages_url, params: { message: { content: 'test', ooc: 'false', chat_id: @chat.id } }
    end

    assert_redirected_to new_user_session_url
  end

  test 'should update message' do
    sign_in(@user)
    patch message_url(@message), params: { message: { content: 'test', ooc: true } }
    assert :success
  end

  test 'unauthorized user should not update message' do
    sign_in(@user2)
    patch message_url(@message), params: { message: { content: 'test', ooc: true } }
    assert_redirected_to root_url
  end

  test 'previously sent message should not update if user left chat' do
    sign_in(@user)
    post messages_url, params: { message: { content: 'test', ooc: false, chat_id: @chat.id } }
    @chat.users.delete(@user)
    patch message_url(@message), params: { message: { content: 'test', ooc: true } }
    assert_redirected_to root_url
  end

  test 'not logged in should not update message' do
    patch message_url(@message), params: { message: { content: 'test', ooc: true } }
    assert_redirected_to new_user_session_url
  end
end
