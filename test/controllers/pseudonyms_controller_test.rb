# frozen_string_literal: true

require 'test_helper'

class PseudonymsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @pseudonym = pseudonyms(:user)
    @posted = pseudonyms(:posted)
    @draft = pseudonyms(:draft)
    @shadowbanned_pseud = pseudonyms(:shadowbanned)

    @user = users(:user)
    @user2 = users(:user_two)
    @john = users(:john)
    @shadowbanned = users(:shadowbanned)
    @admin = users(:admin)
  end

  test 'should get index' do
    sign_in(@user)
    get pseudonyms_url
    assert_response :success
  end

  test 'should get new' do
    sign_in(@user)
    get new_pseudonym_url
    assert_response :success
  end

  test 'should create pseudonym' do
    sign_in(@user)
    assert_difference('Pseudonym.count') do
      post pseudonyms_url, params: {
        pseudonym: {
          name: 'new_guy',
          status: 'posted'
        }
      }
    end

    assert_redirected_to pseudonym_url(Pseudonym.find_by(name: 'new_guy'))
  end

  test 'should show own posted pseudonym' do
    sign_in(@john)
    get pseudonym_url(@posted)
    assert_response :success
  end

  test 'should show someone elses posted pseudonym' do
    sign_in(@user)
    get pseudonym_url(@posted)
    assert_response :success
  end

  test 'should show own drafted pseudonym' do
    sign_in(@john)
    get pseudonym_url(@draft)
    assert_response :success
  end

  test 'should not show someone elses drafted pseudonym' do
    sign_in(@user)
    get pseudonym_url(@draft)
    assert_response :missing
  end

  test 'should get edit' do
    sign_in(@user)
    get edit_pseudonym_url(@pseudonym)
    assert_response :success
  end

  test 'should not get edit for someone elses pseudonym' do
    sign_in(@user2)
    get edit_pseudonym_url(@pseudonym)
    assert_response :missing
  end

  test 'should update pseudonym name and status' do
    sign_in(@user)

    name = @pseudonym.name

    patch pseudonym_url(@pseudonym), params: {
      pseudonym: { name: 'new_name238291', status: 'posted' }
    }

    assert_redirected_to pseudonym_url(@pseudonym)

    @pseudonym.reload
    assert_not_equal(name, @pseudonym.name)
  end

  test 'should destroy pseudonym' do
    sign_in(@user)
    assert_difference('Pseudonym.count', -1) do
      delete pseudonym_url(@pseudonym)
    end

    assert_redirected_to pseudonyms_url
  end

  test 'normal user should not see shadowbanned pseud' do
    sign_in(@user)
    get pseudonyms_url

    assert_select 'h2', { count: 0, text: @shadowbanned_pseud.name }
  end

  test 'shadowbanned user should see shadowbanned pseud and normal pseud' do
    sign_in(@shadowbanned)
    get pseudonyms_url

    assert_select 'h2', @shadowbanned_pseud.name
    assert_select 'h2', @pseudonym.name
  end

  test 'admin user should see shadowbanned pseud' do
    sign_in(@admin)
    get pseudonyms_url

    assert_select 'h2', @shadowbanned_pseud.name
  end
end
