# frozen_string_literal: true

require 'test_helper'

class CharacterTest < ActiveSupport::TestCase
  setup do
    @character = characters(:one)
    @first_tag_for_char = object_tags(:char_one_suite1)
    @user = users(:user)

    @generic = tags(:generic)
    @generic1 = Tag.create(name: '1', tag_type: 'misc', polarity: 'misc', parent: @generic)
    @generic2 = Tag.create(name: '2', tag_type: 'misc', polarity: 'misc', parent: @generic1)
    @generic3 = Tag.create(name: '3', tag_type: 'misc', polarity: 'misc', parent: @generic2)

    @modernfan = tags(:modernfan)
    @twentiethcenturyfantasy = tags(:twentiethcenturyfantasy)

    @disabled = tags(:disabled)

    @no_tags = characters(:no_tags)
  end

  test "can only create #{Ticket::MAX_PER_DAY}" do
    (1..Ticket::MAX_PER_DAY).each do |n|
      assert_nothing_raised do
        Character.create!(
          description: "Some character text part #{n}",
          status: 'posted',
          user: @user
        )
      end
    end

    assert_raises ActiveRecord::RecordInvalid do
      Character.create!(
        description: "Lorem ipsum #{'filler' * 5}",
        user: @user
      )
    end
  end

  test 'deleting a character should delete character tags without deleting the tag itself' do
    assert_nothing_raised do
      @first_tag_for_char.reload
    end

    actual_tag = @first_tag_for_char.tag

    @character.destroy
    assert_raises ActiveRecord::RecordNotFound do
      @first_tag_for_char.reload
    end

    assert_nothing_raised do
      actual_tag.reload
    end
  end

  test 'if a tag with a parent is added to a character, its ancestors should be added too' do
    assert_difference('@character.tags.count', 3) do
      @character.tags << @generic3
      @character.process_tags
      @character.save
    end
  end

  test 'if a tag with a synonym is added to a character, its synonym should be added instead' do
    @no_tags.tags << @twentiethcenturyfantasy

    start_id = @twentiethcenturyfantasy.id
    end_id = @modernfan.id

    assert_changes('@no_tags.tags[0].id', 'Synonym was not replaced', from: start_id, to: end_id) do
      @no_tags.process_tags
      @no_tags.save!
    end
  end

  test 'if a disabled tag is added to a character, it should be removed' do
    assert_no_changes('@no_tags.tags.count', 'Disabled tag was not removed') do
      @no_tags.tags << @disabled
      @no_tags.process_tags
      @no_tags.save!
    end
  end
end
