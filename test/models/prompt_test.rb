# frozen_string_literal: true

require 'test_helper'

class PromptTest < ActiveSupport::TestCase
  setup do
    @prompt = prompts(:one)
    @first_tag_for_prompt = object_tags(:one_suite1)
    @user = users(:user)

    @generic = tags(:generic)
    @generic1 = Tag.create(name: '1', tag_type: 'misc', polarity: 'misc', parent: @generic)
    @generic2 = Tag.create(name: '2', tag_type: 'misc', polarity: 'misc', parent: @generic1)
    @generic3 = Tag.create(name: '3', tag_type: 'misc', polarity: 'misc', parent: @generic2)

    @modernfan = tags(:modernfan)
    @twentiethcenturyfantasy = tags(:twentiethcenturyfantasy)

    @disabled = tags(:disabled)

    @no_tags = prompts(:no_tags)
  end

  test "can only create #{Ticket::MAX_PER_DAY}" do
    (1..Ticket::MAX_PER_DAY).each do |n|
      assert_nothing_raised do
        Prompt.create!(
          starter: "Some ic text part #{n}",
          status: 'posted',
          user: @user
        )
      end
    end

    assert_raises ActiveRecord::RecordInvalid do
      Prompt.create!(
        starter: "Lorem ipsum #{'filler' * 5}",
        user: @user
      )
    end
  end

  test 'deleting a prompt should delete prompt tags without deleting the tag itself' do
    assert_nothing_raised do
      @first_tag_for_prompt.reload
    end

    actual_tag = @first_tag_for_prompt.tag

    @prompt.destroy
    assert_raises ActiveRecord::RecordNotFound do
      @first_tag_for_prompt.reload
    end

    assert_nothing_raised do
      actual_tag.reload
    end
  end

  test 'if a tag with a parent is added to a prompt, its ancestors should be added too' do
    assert_difference('@prompt.tags.count', 3) do
      @prompt.tags << @generic3
      @prompt.process_tags
      @prompt.save
    end
  end

  test 'if a tag with a synonym is added to a prompt, its synonym should be added instead' do
    @no_tags.tags << @twentiethcenturyfantasy

    start_id = @twentiethcenturyfantasy.id
    end_id = @modernfan.id

    assert_changes('@no_tags.tags[0].id', 'Synonym was not replaced', from: start_id, to: end_id) do
      @no_tags.process_tags
      @no_tags.save!
    end
  end

  test 'if a disabled tag is added to a prompt, it should be removed' do
    @no_tags.tags << @disabled

    assert_changes('@no_tags.tags.count', 'Disabled tag was not removed', from: 1, to: 0) do
      @no_tags.process_tags
      @no_tags.save!
    end
  end

  test 'if a tag\'s tag_type has a parent, add that parent' do
    meta_kv = CardinalSettings::Tags.types.find { |_k, v| v['parent'].present? }
    skip if meta_kv.nil? # we need to have tag types with parents in the first place

    type_key = meta_kv.first
    type_hash = meta_kv.last
    tag_name =
      if type_hash.key?('entries')
        type_hash['entries'].first
      elsif type_hash['fill_in']
        'testing meta tags'
      end
    tag_to_add = Tag.find_or_create_with_downcase(
      polarity: type_hash['polarities'].first,
      tag_type: type_key,
      name: tag_name
    )

    tag_components = type_hash['parent']
    parent_tag = Tag.find_or_create_with_downcase(
      polarity: tag_components['polarity'],
      tag_type: tag_components['type'],
      name: tag_components['name']
    )
    assert_raises(ActiveRecord::RecordNotFound) { @no_tags.tags.find(parent_tag.id) }

    @no_tags.tags << tag_to_add
    @no_tags.process_tags

    assert(@no_tags.tags.exists?(id: parent_tag.id))
  end

  test 'cannot bump the same prompt twice in a row' do
    assert @prompt.bump!
    assert_empty @prompt.errors[:bump]

    assert_not @prompt.bump!
    assert_not_empty @prompt.errors[:bump]
  end

  test 'can bump the same prompt after 24 hours' do
    assert @prompt.bump!
    assert_empty @prompt.errors[:bump]

    future = DateTime.now + 1.day
    travel_to(future)

    assert @prompt.bump!
    assert_empty @prompt.errors[:bump]
  end
end
