# frozen_string_literal: true

require 'test_helper'

class PromptsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @prompt = prompts(:one)
    @prompt_without_tags = prompts(:no_tags)
    @user = users(:user)
    @user2 = users(:user_two)
    @admin = users(:admin)
  end

  test 'should get index' do
    sign_in(@user)
    get prompts_url
    assert_response :success
  end

  test 'should get index with tag search' do
    sign_in(@user)
    get prompts_url, params: {
      tags: 'playing:fandom:No Fandom,playing:character:Original Character,playing:characteristic:Tall'
    }
    assert_response :success
  end

  test 'should get search page' do
    sign_in(@user)
    get search_path
    assert_response :success
  end

  test 'should get new' do
    sign_in(@user)
    get new_prompt_url
    assert_response :success
  end

  test 'valid tag parameters should pass' do
    params = ActionController::Parameters.new(
      {
        tags: {
          meta: {
            type: ['Some generic type tag, Another type tag']
          },
          playing: {
            fandom: ['A piece of media'],
            character: ['Character in ^ media']
          }
        }
      }
    )

    permitted = params.require(:tags).permit(**CardinalSettings::Tags.allowed_type_params)

    assert permitted.key?(:meta)
    assert permitted[:meta].key?(:type)

    assert permitted.key?(:playing)
    assert permitted[:playing].key?(:fandom)
    assert permitted[:playing].key?(:character)
  end

  test 'tag parameters with invalid keys should not pass' do
    params = ActionController::Parameters.new(
      {
        tags: {
          not_a_valid_key: ['Some generic tag', 'Another tag'],
          meta: [
            { not_a_good_key: ['hm'] }
          ]
        }
      }
    )

    permitted = params.require(:tags).permit(**CardinalSettings::Tags.allowed_type_params)

    assert_not permitted.key?(:not_a_valid_key)
    assert_not permitted[:meta][0].key?(:not_a_good_key)
  end

  test 'tag parameters with invalid values should not pass' do
    params = ActionController::Parameters.new(
      {
        tags: {
          meta: { bad_value: 'hi' },
          playing: [['bad'], ['value']],
          seeking: [tag: { prompt_id: 1, user_id: 99 }],
          misc: { fandom: ['Huh?'] }
        }
      }
    )

    permitted = params.require(:tags).permit(**CardinalSettings::Tags.allowed_type_params)

    assert_not permitted[:meta].key?(:bad_value)
    assert permitted[:playing].length.zero?
    assert_not permitted[:seeking][0].key?(:tag)
    assert_not permitted[:misc].key?(:fandom)
  end

  test 'should create prompt' do
    sign_in(@user)
    assert_difference('Prompt.count') do
      post prompts_url, params: {
        prompt: { ooc: 'Some unique ooc text', starter: 'Some unique starter text' },
        tags: {
          misc: {
            misc: ['This is a misc tag']
          }
        }
      }
    end

    assert_redirected_to prompt_url(Prompt.find_by(ooc: 'Some unique ooc text'))
  end

  test 'should create prompt with just ooc' do
    sign_in(@user)
    assert_difference('Prompt.count') do
      post prompts_url, params: {
        prompt: { ooc: 'Some unique ooc text' },
        tags: {
          misc: {
            misc: ['This is a misc tag']
          }
        }
      }
    end

    assert_redirected_to prompt_url(Prompt.find_by(ooc: 'Some unique ooc text'))
  end

  test 'should create prompt with just starter' do
    sign_in(@user)
    assert_difference('Prompt.count') do
      post prompts_url, params: {
        prompt: { starter: 'Some unique starter text' },
        tags: {
          misc: {
            misc: ['This is a misc tag']
          }
        }
      }
    end

    assert_redirected_to prompt_url(Prompt.find_by(starter: 'Some unique starter text'))
  end

  test 'should not create prompt with really long tag' do
    sign_in(@user)
    post prompts_url, params: {
      prompt: { starter: 'Some unique starter text' },
      tags: {
        misc: {
          misc: ["This tag is really#{' really' * 500} long"]
        }
      }
    }

    assert_response :unprocessable_entity
  end

  test 'should show prompt' do
    sign_in(@user)
    get prompt_url(@prompt)
    assert_response :success
  end

  test 'should get edit' do
    sign_in(@user)
    get edit_prompt_url(@prompt)
    assert_response :success
  end

  test 'should update prompt' do
    sign_in(@user)
    patch prompt_url(@prompt), params: { prompt: { ooc: 'Some unique ooc text', starter: 'Some unique starter text' } }
    assert_redirected_to prompt_url(@prompt)
  end

  test 'should update prompt to have tags' do
    sign_in(@user)

    assert_difference('PromptTag.count', 7) do
      patch prompt_tags_url(@prompt_without_tags), params: {
        tags: {
          playing: {
            fandom: ['Some Fandom?'], # 1
            character: ['A Guy'], # 2
            characteristic: ['Short'] # 3
          },
          seeking: {
            fandom: ['Some Other Fandom?'], # 4
            character: ['Another guy'], # 5
            characteristic: ['Tall'] # 6
          },
          misc: {
            misc: ['This is a misc tag'] # 7
          }
        }
      }
    end

    assert_redirected_to prompt_url(@prompt_without_tags)
  end

  test 'updating a prompt with tags should remove old tags' do
    sign_in(@user)

    old_amount = @prompt.tags.count
    assert old_amount > 1

    assert_changes('PromptTag.count', from: old_amount, to: 1) do
      patch prompt_tags_url(@prompt), params: {
        tags: {
          misc: {
            misc: ['This is a misc tag'] # 1
          }
        }
      }
    end

    assert_redirected_to prompt_url(@prompt)
  end

  test 'should update arbitrary prompt as admin' do
    sign_in(@admin)
    patch prompt_url(@prompt), params: { prompt: { ooc: 'Some unique ooc text', starter: 'Some unique starter text' } }
    assert_redirected_to prompt_url(@prompt)
  end

  test 'should bump prompt' do
    sign_in(@user)
    patch prompt_bump_path(@prompt)
    assert_redirected_to prompt_url(@prompt)
  end

  test 'should bump prompt after 24 hours' do
    sign_in(@user)
    patch prompt_bump_path(@prompt)
    assert_redirected_to prompt_url(@prompt)

    future = DateTime.now + 1.day
    travel_to(future)

    patch prompt_bump_path(@prompt)
    assert_redirected_to prompt_url(@prompt)
  end

  test 'should not bump prompt' do
    sign_in(@user)
    patch prompt_bump_path(@prompt)
    assert_redirected_to prompt_url(@prompt)

    patch prompt_bump_path(@prompt)
    assert_response :unprocessable_entity
  end

  test 'not logged in should not bump prompt' do
    patch prompt_bump_path(@prompt)
    assert_redirected_to new_user_session_url
  end

  test 'should destroy prompt' do
    sign_in(@user)
    assert_difference('Prompt.count', -1) do
      delete prompt_url(@prompt)
    end

    assert_redirected_to prompts_url
  end
end
