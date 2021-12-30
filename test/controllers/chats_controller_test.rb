# frozen_string_literal: true

require 'test_helper'

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chat = chats(:chat_one)
    @user = users(:user)
    @user2 = users(:user_two)
    @chat.users << @user << @user2
  end

  test 'should get index' do
    sign_in(@user)
    get chats_url
    assert_response :success
  end

  test 'should create chat' do
    sign_in(@user)
    assert_difference('Chat.count') do
      post chats_url
    end

    assert_redirected_to chat_url(Chat.last.uuid)
  end

  test 'should show chat' do
    sign_in(@user)
    get chat_url(@chat.uuid)
    assert_response :success
  end

  test 'should get edit' do
    sign_in(@user)
    get edit_chat_url(@chat.uuid)
    assert_response :success
  end

  test 'should update chat' do
    sign_in(@user)
    patch chat_path(@chat.uuid), params: { chat: { title: 'test', description: 'test' } }
    assert_redirected_to chat_path(@chat.uuid)
  end

  test 'should destroy chat' do
    sign_in(@user)
    assert_difference('ChatUser.count', -1) do
      delete chat_path(@chat.uuid)
    end

    assert_redirected_to chats_url
  end
end
