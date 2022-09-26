# frozen_string_literal: true

require 'test_helper'

class ConnectCodeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chat = chats(:chat_one)
    @chat2 = chats(:chat_two)
    @user = users(:user)
    @user2 = users(:user_two)
    @user3 = users(:user_three)

    @connect_code = connect_codes(:chat_one)
    @connect_code2 = connect_codes(:chat_two)

    @chat.users << @user << @user2
  end

  test 'should use connect code' do
    sign_in(@user3)

    assert_difference('@chat.users.count', 1) do
      patch connect_code_consume_path, params: {
        connect_code: @connect_code.code
      }
    end

    assert_redirected_to chat_url(@chat.uuid)
  end

  test 'should not use connect code if already in chat' do
    sign_in(@user2)

    original_count = @chat.users.count.to_i

    assert_raises ActiveRecord::RecordInvalid do
      patch connect_code_consume_path, params: {
        connect_code: @connect_code.code
      }
    end

    new_count = @chat.users.count.to_i

    assert_equal(
      original_count,
      new_count,
      "#{original_count} does not equal #{new_count}, The connect code was consumed."
    )
  end

  test 'should not use connect code without open slots' do
    sign_in(@user3)

    original_count = @chat2.users.count.to_i

    patch connect_code_consume_path, params: {
      connect_code: @connect_code2.code
    }

    assert_redirected_to chats_path

    new_count = @chat2.users.count.to_i

    assert_equal(
      original_count,
      new_count,
      "#{original_count} does not equal #{new_count}, The connect code was consumed."
    )
  end

  test 'should update connect code' do
    sign_in(@user)

    assert_difference('@connect_code2.reload.remaining_uses', 1) do
      patch connect_code_path, params: {
        connect_code: @connect_code2.code,
        remaining_uses: 1
      }
    end

    assert_redirected_to edit_chat_url(@chat2.uuid)
  end

  test 'should not update connect code unless chat admin' do
    sign_in(@user3)

    assert_difference('@connect_code.reload.remaining_uses', 0) do
      patch connect_code_path, params: {
        connect_code: @connect_code.code,
        remaining_uses: 1
      }
    end

    assert_redirected_to edit_chat_url(@chat.uuid)
  end
end
