# frozen_string_literal: true

require 'test_helper'

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @message = messages(:user)
    @admin = users(:admin)
    @user = users(:user)
    @user2 = users(:user_two)
    @user3 = users(:user_three)
    @shadowbanned = users(:shadowbanned)

    @chat = chats(:chat_one)
    @chat_shadowbanned = chats(:chat_shadowbanned)

    @chat_shadowbanned.users << @shadowbanned
    @chat_shadowbanned.users << @user
    @chat_shadowbanned.chat_users.each(&:ongoing!)

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

    assert_response :missing
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

    assert_response :missing
  end

  test 'previously sent message should not update if user left chat' do
    sign_in(@user)
    post messages_url, params: { message: { content: 'test', ooc: false, chat_id: @chat.id } }
    @chat.users.delete(@user)

    patch message_url(@message), params: { message: { content: 'test', ooc: true } }

    assert_response :missing
  end

  test 'not logged in should not update message' do
    patch message_url(@message), params: { message: { content: 'test', ooc: true } }
    assert_redirected_to new_user_session_url
  end

  test 'should get message history as admin' do
    sign_in(@admin)
    get history_message_url(@message)
    assert_response :ok
  end

  test 'should get message history as owner' do
    sign_in(@user)
    get history_message_url(@message)
    assert_response :ok
  end

  test 'should not get message history as non-owner' do
    sign_in(@user2)
    get history_message_url(@message)
    assert_response :missing
  end

  test 'shadowbanned user should not update chat_user status of normal user' do
    sign_in(@shadowbanned)
    post messages_url, params: { message: { content: 'test', ooc: false, chat_id: @chat_shadowbanned.id } }

    assert @chat_shadowbanned.chat_users.find_by(user: @user).ongoing?
  end

  test 'normal user should update chat_user status of shadowbanned' do
    sign_in(@user)
    post messages_url, params: { message: { content: 'test', ooc: false, chat_id: @chat_shadowbanned.id } }

    assert_not @chat_shadowbanned.chat_users.find_by(user: @shadowbanned).ongoing?
  end
end
