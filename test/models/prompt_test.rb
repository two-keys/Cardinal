# frozen_string_literal: true

require 'test_helper'

class PromptTest < ActiveSupport::TestCase
  setup do
    @prompt = prompts(:one)
    @first_tag_for_prompt = object_tags(:one_suite1)
    @user = users(:user)

    @generic = tags(:generic)
    @generic1 = Tag.create(name: '1', tag_type: 'detail', polarity: 'misc', parent: @generic)
    @generic2 = Tag.create(name: '2', tag_type: 'detail', polarity: 'misc', parent: @generic1)
    @generic3 = Tag.create(name: '3', tag_type: 'detail', polarity: 'misc', parent: @generic2)

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
    @no_tags.process_tags # Prepopulate system-managed tags
    @no_tags.save!

    @no_tags.tags << @disabled

    assert_changes('@no_tags.tags.count', 'Disabled tag was not removed', from: 3, to: 2) do
      @no_tags.process_tags
      @no_tags.save!
    end
  end

  test 'cannot bump the same prompt twice in a row' do
    assert @prompt.bump!
    assert_empty @prompt.errors[:bump]

    assert_not @prompt.bump!
    assert_not_empty @prompt.errors[:bump]
  end

  test "can bump the same prompt after #{Prompt::BUMP_WAIT_TIME.in_hours} hours" do
    assert @prompt.bump!
    assert_empty @prompt.errors[:bump]

    future = DateTime.now + Prompt::BUMP_WAIT_TIME + 1.second
    travel_to(future)

    assert @prompt.bump!
    assert_empty @prompt.errors[:bump]
  end
end
