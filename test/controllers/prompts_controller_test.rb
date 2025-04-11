# frozen_string_literal: true

require 'test_helper'

class PromptsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @prompt = prompts(:one)
    @prompt_without_tags = prompts(:no_tags)
    @posted = prompts(:posted)
    @draft = prompts(:draft)
    @prompt_shadowbanned = prompts(:shadowbanned)

    @character = characters(:one)
    @character2 = characters(:two)

    @user_pseud2 = pseudonyms(:user_second)
    @user2_pseud = pseudonyms(:user_two)

    @user = users(:user)
    @user2 = users(:user_two)
    @john = users(:john)
    @system = users(:system)
    @admin = users(:admin)
    @banned = users(:user_banned)
    @shadowbanned = users(:shadowbanned)
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

  test 'should get index with NOT tag search' do
    sign_in(@user)
    get prompts_url, params: {
      nottags: 'playing:fandom:No Fandom,playing:character:Original Character,playing:characteristic:Tall'
    }
    assert_response :success
  end

  test 'should get search page' do
    sign_in(@user)
    get prompts_search_path
    assert_response :success
  end

  test 'should get simple filter pages' do
    sign_in(@user)
    %w[blacklist whitelist].each do |variant|
      get filters_simple_path, params: { variant: }
      assert_response :success
    end
  end

  test 'should create advanced search' do
    sign_in(@user)
    tags = {
      playing: {
        fandom: ['No Fandom'],
        character: ['Original Character'],
        gender: ['Cis Female']
      },
      misc: {
        detail: ['Test']
      }
    }

    post prompts_search_path, params: { tags: }

    expected_tags = tags.map do |polarity, p_hash|
      p_hash.map do |tag_type, names|
        names.map do |name|
          "#{polarity}:#{tag_type}:#{name}"
        end
      end
    end

    tag_string = expected_tags.join(',')

    assert_redirected_to "/prompts?tags=#{CGI.escape(tag_string)}"
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
            genre: ['Romance']
          },
          playing: {
            fandom: ['A piece of media'],
            character: ['Character in ^ media']
          }
        }
      }
    )

    permitted = params.require(:tags).permit(**TagSchema::PromptTagSchema.allowed_type_params)

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

    permitted = params.require(:tags).permit(**TagSchema::PromptTagSchema.allowed_type_params)

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

    permitted = params.require(:tags).permit(**TagSchema::PromptTagSchema.allowed_type_params)

    assert_not permitted[:meta].key?(:bad_value)
    assert permitted[:playing].empty?
    assert_not permitted[:seeking][0].key?(:tag)
    assert_not permitted[:misc].key?(:fandom)
  end

  test 'should create prompt' do
    sign_in(@user)
    assert_difference('Prompt.count') do
      post prompts_url, params: {
        characters: ['-1'],
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
        characters: ['-1'],
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
        characters: ['-1'],
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
      characters: ['-1'],
      prompt: { starter: 'Some unique starter text' },
      tags: {
        misc: {
          detail: ["This tag is really#{' really' * 500} long"]
        }
      }
    }

    assert_response :unprocessable_entity
  end

  test 'shoud create prompt with two slots' do
    sign_in(@user)
    assert_difference('Prompt.count') do
      post prompts_url, params: {
        characters: ['-1'],
        prompt: {
          starter: 'Some unique starter text',
          default_slots: 2
        },
        tags: {
          misc: {
            misc: ['This is a misc tag']
          }
        }
      }
    end

    assert_redirected_to prompt_url(Prompt.find_by(starter: 'Some unique starter text'))
  end

  test 'should not create prompt with just one slot' do
    sign_in(@user)
    post prompts_url, params: {
      characters: ['-1'],
      prompt: {
        starter: 'Some unique starter text',
        default_slots: 1
      },
      tags: {
        misc: {
          misc: ['This is a misc tag']
        }
      }
    }

    assert_response :unprocessable_entity
  end

  test 'should update pseudonym on a prompt' do
    sign_in(@user)
    assert_changes('@prompt.reload.pseudonym.name') do
      patch prompt_url(@prompt), params: { prompt: { pseudonym_id: @user_pseud2.id } }
    end
  end

  test 'should not attach a pseudonym you dont own' do
    sign_in(@user)
    assert_no_changes('@prompt.reload.pseudonym.name') do
      patch prompt_url(@prompt), params: { prompt: { pseudonym_id: @user2_pseud.id } }
    end
  end

  test 'should show own posted prompt' do
    sign_in(@john)
    get prompt_url(@posted)
    assert_response :success
  end

  test 'should show someone elses posted prompt' do
    sign_in(@user)
    get prompt_url(@posted)
    assert_response :success
  end

  test 'should show own drafted prompt' do
    sign_in(@john)
    get prompt_url(@draft)
    assert_response :success
  end

  test 'should not show someone elses drafted prompt' do
    sign_in(@user)
    get prompt_url(@draft)
    assert_response :missing
  end

  test 'should get edit' do
    sign_in(@user)
    get edit_prompt_url(@prompt)
    assert_response :success
  end

  test 'should not get edit for someone elses prompt' do
    sign_in(@user2)
    get edit_prompt_url(@prompt)
    assert_response :missing
  end

  test 'should update prompt' do
    sign_in(@user)

    assert_changes('@prompt.reload.ooc') do
      patch prompt_url(@prompt),
            params: { prompt: { ooc: 'Some unique ooc text', starter: 'Some unique starter text' } }
    end
    assert_redirected_to prompt_url(@prompt)
  end

  test 'should update prompt even after spending tickets' do
    sign_in(@user)

    (1..Ticket::MAX_PER_DAY).each do
      Ticket.create!(user: @user, item: @prompt, created_at: 1.hour.ago)
    end

    assert_changes('@prompt.reload.ooc') do
      patch prompt_url(@prompt), params: {
        prompt: {
          ooc: 'Some unique ooc text',
          starter: 'Some unique starter text',
          status: 'posted'
        }
      }
    end

    assert_redirected_to prompt_url(@prompt)
  end

  test 'should update prompt to have tags' do
    sign_in(@user)

    assert_difference('ObjectTag.count', 7) do
      patch prompt_tags_url(@prompt_without_tags), params: {
        characters: ['-1'],
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
            detail: ['This is a misc tag'] # 7
          }
        }
      }
    end

    assert_redirected_to prompt_url(@prompt_without_tags)
  end

  test 'should update prompt to have characters' do
    sign_in(@user)

    assert_difference('ObjectCharacter.count', 1) do
      patch prompt_tags_url(@prompt_without_tags), params: {
        characters: [@character.id.to_s],
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

  test 'should not update prompt to have someone elses character' do
    sign_in(@user)

    assert_no_changes('ObjectCharacter.where(object_type: \'Prompt\', object_id: @prompt_without_tags.id).count') do
      patch prompt_tags_url(@prompt_without_tags), params: {
        characters: [@character2.id.to_s],
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
  end

  test 'updating a prompt with tags should remove old tags' do
    sign_in(@user)

    old_amount = @prompt.tags.count
    assert old_amount > 1

    assert_changes('ObjectTag.where(object_type: \'Prompt\', object_id: @prompt.id).count', from: old_amount, to: 1) do
      patch prompt_tags_url(@prompt), params: {
        characters: ['-1'],
        tags: {
          misc: {
            detail: ['This is a misc tag'] # 1
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

  test "should bump prompt after #{Prompt::BUMP_WAIT_TIME.in_hours} hours" do
    sign_in(@user)
    patch prompt_bump_path(@prompt)
    assert_redirected_to prompt_url(@prompt)

    future = DateTime.now + Prompt::BUMP_WAIT_TIME + 1.second
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

  test 'should answer prompt' do
    sign_in(@user2)
    post prompt_answer_path(@prompt)

    assert_response :redirect

    reg_exp_for_url = %r{http://www\.example\.com/chats/(.*)}
    assert_match reg_exp_for_url, @response.redirect_url

    matches = %r{http://www\.example\.com/chats/(?<uuid>.*)}.match(@response.redirect_url)
    chat = Chat.find_by(uuid: matches['uuid'])

    assert_includes chat.messages.pluck(:content), @prompt.ooc
    assert_includes chat.messages.pluck(:content), @prompt.starter
  end

  test 'should not answer own prompt' do
    sign_in(@user)
    post prompt_answer_path(@prompt)

    assert_response :unprocessable_entity
  end

  test 'banned should not answer prompt' do
    sign_in(@banned)
    post prompt_answer_path(@prompt)

    assert_redirected_to new_user_session_path
  end

  test 'should destroy prompt' do
    sign_in(@user)
    assert_difference('Prompt.count', -1) do
      delete prompt_url(@prompt)
    end

    assert_redirected_to prompts_url
  end

  test 'should get prompt history as admin' do
    sign_in(@admin)
    get history_prompt_url(@prompt)
    assert_response :ok
  end

  test 'should get prompt history as owner' do
    sign_in(@user)
    get history_prompt_url(@prompt)
    assert_response :ok
  end

  test 'should not get prompt history as non-owner' do
    sign_in(@user2)
    get history_prompt_url(@prompt)
    assert_response :missing
  end

  test 'shadowbanned should see own prompt and others in directory' do
    sign_in(@shadowbanned)
    get prompts_url
    assert_select 'p', @prompt_shadowbanned.ooc
    assert_select 'p', @posted.ooc
  end

  test 'admin should see shadowbanned prompt in directory' do
    sign_in(@admin)
    get prompts_url
    assert_select 'p', @prompt_shadowbanned.ooc
  end

  test 'normal user should not see shadowbanned prompt in directory' do
    sign_in(@user)
    get prompts_url
    assert_select 'p', { count: 0, text: @prompt_shadowbanned.ooc }
  end

  test 'shadowbanned user answering prompt connects to system user instead' do
    sign_in(@shadowbanned)
    post prompt_answer_path(@prompt)

    assert_response :redirect

    reg_exp_for_url = %r{http://www\.example\.com/chats/(.*)}
    assert_match reg_exp_for_url, @response.redirect_url

    matches = %r{http://www\.example\.com/chats/(?<uuid>.*)}.match(@response.redirect_url)
    chat = Chat.find_by(uuid: matches['uuid'])

    user = chat.users.where.not(id: @shadowbanned.id).first

    assert user.id.zero?
  end
end
