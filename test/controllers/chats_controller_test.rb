# frozen_string_literal: true

require 'test_helper'

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chat = chats(:chat_one)
    @shadowbanned_chat = chats(:chat_shadowbanned)

    @user = users(:user)
    @user2 = users(:user_two)
    @admin = users(:admin)
    @shadowbanned = users(:shadowbanned)

    @user_pseud = pseudonyms(:user)
    @user_pseud2 = pseudonyms(:user_second)
    @user2_pseud = pseudonyms(:user_two)

    @shadowbanned_chat.chat_users << ChatUser.new(user: @shadowbanned)
    @shadowbanned_chat.chat_users << ChatUser.new(user: @user)

    @unshadowbanned_message = messages(:user_message_with_shadowban)
    @shadowbanned_message = messages(:user_shadowbanned_message)

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
          params: { chat: { title: 'test', description: 'test', pseudonym_id: nil, icon: chat_user.icon,
                            color: '#000000' } }
    assert_redirected_to edit_chat_path(@chat.uuid)
  end

  test 'should update chat to have pseudonym' do
    sign_in(@user)
    chat_user = @chat.chat_users.where(user: @user).first
    assert_changes('@chat_user.reload.pseudonym.name') do
      patch chat_path(@chat.uuid), params: {
        chat: { title: 'test', description: 'test', pseudonym_id: @user_pseud2.id, icon: chat_user.icon,
                color: '#000000' }
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

  test 'shadowbanned should see all messages' do
    sign_in(@shadowbanned)
    get chat_url(@shadowbanned_chat.uuid)

    assert_select 'p', @shadowbanned_message.content
    assert_select 'p', @unshadowbanned_message.content
  end

  test 'admin should see all messages' do
    sign_in(@admin)
    get chat_url(@shadowbanned_chat.uuid)

    assert_select 'p', @shadowbanned_message.content
    assert_select 'p', @unshadowbanned_message.content
  end

  test 'normal user should not see shadowbanned messages' do
    sign_in(@user)
    get chat_url(@shadowbanned_chat.uuid)

    assert_select 'p', { count: 0, text: @shadowbanned_message.content }
    assert_select 'p', @unshadowbanned_message.content
  end

  test 'normal user should not see shadowbanned message in chats list' do
    Message.create(user: @user, content: 'new normal message', chat: @shadowbanned_chat)
    Message.create(user: @shadowbanned, content: 'new shadowbanned message', chat: @shadowbanned_chat)
    sign_in(@user)

    get chats_url

    assert_select 'p', { count: 0, text: 'new shadowbanned message' }
    assert_select 'p', 'new normal message'
  end

  test 'shadowbanned user should see shadowbanned message in chats list' do
    Message.create(user: @user, content: 'new normal message', chat: @shadowbanned_chat)
    Message.create(user: @shadowbanned, content: 'new shadowbanned message', chat: @shadowbanned_chat)
    sign_in(@shadowbanned)

    get chats_url

    assert_select 'p', { count: 0, text: 'new normal message' }
    assert_select 'p', 'new shadowbanned message'
  end
end
