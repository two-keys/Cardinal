# frozen_string_literal: true

require 'application_system_test_case'

class PromptsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @prompt = prompts(:one)
    @no_tags = prompts(:no_tags)
    @old_prompt = prompts(:ancient)
    @johns = prompts(:johns)

    @tag_generic = tags(:generic)
    @tag_modern_fantasy = tags(:modernfan)

    sign_in(@user)
  end

  test 'visiting the index' do
    visit prompts_url
    assert_selector 'h1', text: 'Prompts'
  end

  test 'prompts with rejected tags should not show up' do
    bad_tag_objs = (1..3).map do |num|
      { polarity: 'misc', tag_type: 'detail', name: "bad tag #{num}" }
    end

    bad_tags = []
    bad_tag_objs.each do |bt|
      temp_tag = Tag.find_or_create_with_downcase(
        polarity: bt['polarity'],
        tag_type: bt['tag_type'],
        name: bt['name']
      )
      bad_tags << temp_tag
      Filter.create(user: @user, tag: temp_tag, group: 'test', filter_type: 'Rejection')
    end

    @no_tags.tags = bad_tags

    tag_params = bad_tag_objs.map do |bt|
      "#{bt[:polarity]}:#{bt[:tag_type]}:#{bt[:name]}"
    end
    tag_list = tag_params.join(',')

    visit "#{prompts_url}?tags=#{tag_list}"
    assert_selector 'h1', text: 'Prompts'

    assert_no_selector 'p', text: @no_tags.ooc
  end

  test 'visiting the index with search' do
    tag_list = 'playing:fandom:No Fandom'
    tag_list += ',playing:character:Original Character'
    tag_list += ',playing:characteristic:Tall'
    tag_list += ',playing:characteristic:Super Unique 9292922333'

    tag_array = Tag.from_search_params(tag_list)
    @no_tags.tags = tag_array

    visit "#{prompts_url}?tags=#{tag_list}"
    assert_selector 'h1', text: 'Prompts'

    tag_array.each do |tag|
      find 'a', exact_text: tag.name
    end
  end

  test 'visiting the index with NOT search' do
    tag_list = 'playing:fandom:No Fandom'

    tag_array = Tag.from_search_params(tag_list)
    @no_tags.tags = tag_array

    visit "#{prompts_url}?tags=#{tag_list}&nottags=#{tag_list}"
    assert_selector 'h1', text: 'Prompts'

    find 'strong', exact_text: 0
  end

  test 'visiting the index with ?before url parameter' do
    visit "#{prompts_url}?before=1999-12-01"
    assert_selector 'h1', text: 'Prompts'

    find 'p', text: @old_prompt.ooc
  end

  test 'should be able to use advanced search' do
    visit prompts_search_url

    tags_to_look_for = []

    polarity = 'misc'
    tag_type = 'misc'

    text = @tag_generic.name
    text2 = @tag_modern_fantasy.name

    tags_to_look_for << "#{polarity}:#{tag_type}:#{text}"
    tags_to_look_for << "#{polarity}:#{tag_type}:#{text2}"

    input_node = find 'input#tags_misc_misc'

    fill_in input_node[:id], with: "#{text},#{text2}"

    click_button 'Submit Tags'

    path_to_match = prompts_path(tags: tags_to_look_for.join(','))
    assert_current_path(path_to_match)

    assert_text @prompt.starter
  end

  test 'should create prompt' do
    visit prompts_url
    click_on 'New Prompt'

    fill_in 'Ooc', with: '1234928i383 totally unique prompt ooc'
    fill_in 'Starter', with: '1234929adwjwo totally unique prompt starter'
    click_on 'Submit'

    assert_text 'Edit'
    click_on 'Back'
  end

  test 'should create prompt with tags' do
    visit prompts_url
    click_on 'New Prompt'

    tags_to_look_for = []

    fill_in 'Ooc', with: '1234928i383 totally unique prompt ooc'
    TagSchema::PromptTagSchema.types.each do |tag_type|
      next unless TagSchema.fillable?(tag_type)

      type_hash['polarities'].each do |polarity|
        text = "Totally unique #{polarity} #{tag_type} tag"
        tags_to_look_for << text

        input_node = find "input#tags_#{polarity}_#{tag_type}"
        fill_in input_node[:id], with: text
      end
    end
    click_on 'Submit'
    assert_text 'Prompt was successfully created'

    tags_to_look_for.each do |tag_text|
      find 'a', text: tag_text
    end

    click_on 'Back'
  end

  test 'should create prompt with multiple tags in one polarity->tag_type input' do
    visit prompts_url
    click_on 'New Prompt'

    tags_to_look_for = []

    fill_in 'prompt_ooc', with: '1234928i383 totally unique prompt ooc'
    TagSchema::PromptTagSchema.types.each do |tag_type|
      next unless TagSchema.fillable?(tag_type)

      input_node = find 'input#tags_misc_misc'

      (1..30).each do |num|
        tags_to_look_for << "Totally unique misc misc tag #{num}"
      end

      fill_in input_node[:id], with: tags_to_look_for.join(', ')
    end
    find('input[name="commit"]').click
    assert_text 'Prompt was successfully created.', wait: 10

    tags_to_look_for.each do |tag_text|
      find 'a', exact_text: tag_text
    end

    click_on 'Back'
  end

  test 'should create prompt with just ooc' do
    visit prompts_url
    click_on 'New Prompt'

    fill_in 'Ooc', with: '1234928i383 totally unique prompt ooc'
    click_on 'Submit'

    assert_text 'Prompt was successfully created'
    click_on 'Back'
  end

  test 'should create prompt with just starter' do
    visit prompts_url
    click_on 'New Prompt'

    fill_in 'Starter', with: '1234929adwjwo totally unique prompt starter'
    click_on 'Submit'

    assert_text 'Prompt was successfully created'
    click_on 'Back'
  end

  test 'should update Prompt starter and ooc' do
    visit prompt_url(@prompt)
    click_on 'Edit', match: :first

    fill_in 'Ooc', with: @prompt.ooc
    fill_in 'Starter', with: @prompt.starter
    click_on 'Submit', match: :first

    assert_text 'Edit'
    click_on 'Back'
  end

  test 'should answer prompt' do
    visit prompt_url(@johns)
    click_on 'Answer', match: :first

    assert_text @johns.ooc
    click_on 'Back'
  end

  test 'should destroy Prompt' do
    visit prompt_url(@prompt)
    click_on 'Destroy', match: :first

    assert_text 'Prompt was successfully destroyed'
  end
end
