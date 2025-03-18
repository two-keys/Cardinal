# frozen_string_literal: true

require 'test_helper'

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chat = chats(:chat_one)
    @user = users(:user)
    @user2 = users(:user_two)

    @user_pseud = pseudonyms(:user)
    @user_pseud2 = pseudonyms(:user_second)
    @user2_pseud = pseudonyms(:user_two)

    @chat_user = ChatUser.new(user: @user, role: ChatUser.roles[:chat_admin], pseudonym: @user_pseud) # owner
    @chat.chat_users << @chat_user
    @chat.chat_users << ChatUser.new(user: @user2)
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
    chat_user = @chat.chat_users.where(user: @user).first
    patch chat_path(@chat.uuid),
          params: { chat: { title: 'test', description: 'test', pseudonym_id: nil, icon: chat_user.icon } }
    assert_redirected_to chat_path(@chat.uuid)
  end

  test 'should update chat to have pseudonym' do
    sign_in(@user)
    chat_user = @chat.chat_users.where(user: @user).first
    assert_changes('@chat_user.reload.pseudonym.name') do
      patch chat_path(@chat.uuid), params: {
        chat: { title: 'test', description: 'test', pseudonym_id: @user_pseud2.id, icon: chat_user.icon }
      }
    end
  end

  test 'should not update chat to have someone elses pseudonym' do
    sign_in(@user)
    chat_user = @chat.chat_users.where(user: @user).first
    assert_no_changes('@chat_user.reload.pseudonym.name') do
      patch chat_path(@chat.uuid), params: {
        chat: { title: 'test', description: 'test', pseudonym_id: @user2_pseud.id, icon: chat_user.icon }
      }
    end
  end

  test 'should remove from chat' do
    sign_in(@user)
    assert_difference('ChatUser.count', -1) do
      delete chat_path(@chat.uuid)
    end

    assert_redirected_to chats_url
  end

  test 'should actually destroy chat' do
    sign_in(@user2)
    delete chat_path(@chat.uuid)

    sign_in(@user)
    assert_difference('Chat.count', -1) do
      delete chat_path(@chat.uuid)
    end

    assert_redirected_to chats_url
  end

  test 'should kick user if chat admin' do
    sign_in(@user)

    chat_user2 = @chat.chat_users.find_by(user: @user2)
    assert_difference('ChatUser.count', -1) do
      delete chat_kick_path(@chat.uuid, chat_user2.icon)
    end

    assert_redirected_to chats_url
  end

  test 'should not kick user as general chat user' do
    sign_in(@user2)

    chat_user = @chat.chat_users.find_by(user: @user)
    assert_no_difference 'ChatUser.count' do
      delete chat_kick_path(@chat.uuid, chat_user.icon)
    end

    assert_response :missing
  end
end
