# frozen_string_literal: true

require 'test_helper'

class CharactersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @character = characters(:one)
    @character_without_tags = characters(:no_tags)
    @posted = characters(:posted)
    @draft = characters(:draft)
    @shadowbanned_character = characters(:shadowbanned)

    @user_pseud2 = pseudonyms(:user_second)
    @user2_pseud = pseudonyms(:user_two)
    @shadowbanned_pseud = pseudonyms(:shadowbanned)

    @user = users(:user)
    @user2 = users(:user_two)
    @john = users(:john)
    @admin = users(:admin)
    @banned = users(:user_banned)
    @shadowbanned = users(:shadowbanned)
  end

  test 'should get index' do
    sign_in(@user)
    get characters_url
    assert_response :success
  end

  test 'should get index with tag search' do
    sign_in(@user)
    get characters_url, params: {
      tags: 'playing:fandom:No Fandom,playing:character:Original Character,playing:characteristic:Tall'
    }
    assert_response :success
  end

  test 'should get index with NOT tag search' do
    sign_in(@user)
    get characters_url, params: {
      nottags: 'playing:fandom:No Fandom,playing:character:Original Character,playing:characteristic:Tall'
    }
    assert_response :success
  end

  test 'should get search page' do
    sign_in(@user)
    get characters_search_path
    assert_response :success
  end

  test 'should get new' do
    sign_in(@user)
    get new_character_url
    assert_response :success
  end

  test 'valid tag parameters should pass' do
    params = ActionController::Parameters.new(
      {
        tags: {
          meta: {
            genre: ['Romance']
          },
          playing: {
            fandom: ['A piece of media'],
            character: ['Character in ^ media']
          }
        }
      }
    )

    permitted = params.require(:tags).permit(**TagSchema::CharacterTagSchema.allowed_type_params)

    assert permitted.key?(:meta)
    assert permitted[:meta].key?(:genre)

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

    permitted = params.require(:tags).permit(**TagSchema::CharacterTagSchema.allowed_type_params)

    assert_not permitted.key?(:not_a_valid_key)
    assert_not permitted[:meta][0].key?(:not_a_good_key)
  end

  test 'tag parameters with invalid values should not pass' do
    params = ActionController::Parameters.new(
      {
        tags: {
          meta: { bad_value: 'hi', fandom: ['Huh?'] },
          playing: [['bad'], ['value']],
          seeking: [tag: { character_id: 1, user_id: 99 }]
        }
      }
    )

    permitted = params.require(:tags).permit(**TagSchema::CharacterTagSchema.allowed_type_params)

    assert_not permitted[:meta].key?(:bad_value)
    assert_not permitted[:meta].key?(:fandom)
    assert permitted[:playing].empty?
    assert_not permitted.key?(:seeking)
  end

  test 'should create character' do
    sign_in(@user)
    assert_difference('Character.count') do
      post characters_url, params: {
        character: { description: 'Some unique description text' },
        tags: {
          meta: {
            genre: ['Romance']
          },
          playing: {
            gender: ['Cis Male']
          }
        }
      }
    end

    assert_redirected_to character_url(Character.find_by(description: 'Some unique description text'))
  end

  test 'should create character with just description' do
    sign_in(@user)
    assert_difference('Character.count') do
      post characters_url, params: {
        character: { description: 'Some unique description text' },
        tags: {
          meta: {
            genre: ['Romance']
          }
        }
      }
    end

    assert_redirected_to character_url(Character.find_by(description: 'Some unique description text'))
  end

  test 'should not create character with really long tag' do
    sign_in(@user)
    post characters_url, params: {
      character: { starter: 'Some unique starter text' },
      tags: {
        playing: {
          fandom: ["This tag is really#{' really' * 500} long"]
        }
      }
    }

    assert_response :unprocessable_entity
  end

  test 'should show own posted character' do
    sign_in(@john)
    get character_url(@posted)
    assert_response :success
  end

  test 'should show someone elses posted character' do
    sign_in(@user)
    get character_url(@posted)
    assert_response :success
  end

  test 'should show own drafted character' do
    sign_in(@john)
    get character_url(@draft)
    assert_response :success
  end

  test 'should not show someone elses drafted character' do
    sign_in(@user)
    get character_url(@draft)
    assert_response :missing
  end

  test 'should get edit' do
    sign_in(@user)
    get edit_character_url(@character)
    assert_response :success
  end

  test 'should not get edit for someone elses character' do
    sign_in(@user2)
    get edit_character_url(@character)
    assert_response :missing
  end

  test 'should update character' do
    sign_in(@user)
    patch character_url(@character), params: {
      character: { ooc: 'Some unique ooc text', starter: 'Some unique starter text' }
    }
    assert_redirected_to character_url(@character)
  end

  test 'should update character to have tags' do
    sign_in(@user)

    assert_difference('ObjectTag.count', 3) do
      patch character_tags_url(@character_without_tags), params: {
        tags: {
          playing: {
            fandom: ['Some Fandom?'], # 1
            character: ['A Guy'], # 2
            characteristic: ['Short'] # 3
          }
        }
      }
    end

    assert_redirected_to character_url(@character_without_tags)
  end

  test 'updating a character with tags should remove old tags' do
    sign_in(@user)

    old_amount = @character.tags.count
    assert old_amount > 1

    assert_changes(
      'ObjectTag.where(object_type: \'Character\', object_id: @character.id).count',
      from: old_amount,
      to: 1
    ) do
      patch character_tags_url(@character), params: {
        tags: {
          meta: {
            genre: ['Romance']
          }
        }
      }
    end

    assert_redirected_to character_url(@character)
  end

  test 'should update arbitrary character as admin' do
    sign_in(@admin)
    patch character_url(@character), params: {
      character: { ooc: 'Some unique ooc text', starter: 'Some unique starter text' }
    }
    assert_redirected_to character_url(@character)
  end

  test 'should update character to have pseudonym' do
    sign_in(@user)

    assert_changes('@character.reload.pseudonym.name', 1) do
      patch character_url(@character), params: {
        character: { pseudonym_id: @user_pseud2.id }
      }
    end
  end

  test 'should not update character to have someone elses pseudonym' do
    sign_in(@user)

    assert_no_changes('@character.reload.pseudonym.id') do
      patch character_url(@character), params: {
        character: { pseudonym_id: @user2_pseud.id }
      }
    end
  end

  test 'should destroy character' do
    sign_in(@user)
    assert_difference('Character.count', -1) do
      delete character_url(@character)
    end

    assert_redirected_to characters_url
  end

  test 'should get character history as admin' do
    sign_in(@admin)
    get history_character_url(@character)
    assert_response :ok
  end

  test 'should get character history as owner' do
    sign_in(@user)
    get history_character_url(@character)
    assert_response :ok
  end

  test 'should not get character history as non-owner' do
    sign_in(@user2)
    get history_character_url(@character)
    assert_response :missing
  end

  test 'should not see shadowbanned user characters as normal user' do
    sign_in(@user)
    get characters_url

    assert_select 'h2', { count: 0, text: @shadowbanned_character.name }
  end

  test 'should see shadowbanned user characters as admin' do
    sign_in(@admin)
    get characters_url

    assert_select 'h2', @shadowbanned_character.name
  end

  test 'should see shadowbanned user characters as shadowbanned' do
    sign_in(@shadowbanned)
    get characters_url

    assert_select 'h2', @shadowbanned_character.name
  end
end
