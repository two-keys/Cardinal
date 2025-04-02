# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  setup do
    @son_tag = tags(:son)
    @dad_tag = tags(:dad)
    @son_tag.parent = @dad_tag

    @capital = tags(:capital)
    @camel_case = tags(:camel_case)
  end

  test 'lower can be accessed' do
    assert_equal 'capital', @capital.lower
  end

  test 'can get parent from child' do
    assert_equal @dad_tag, @son_tag.parent
  end

  test 'can get children from parent tag' do
    parent_tag = Tag.create(
      name: 'parent',
      tag_type: 'detail',
      polarity: 'misc'
    )

    children = []
    (1..3).each do |n|
      temp_child = Tag.create(
        name: "#{parent_tag.name} child ##{n}",
        tag_type: 'detail',
        polarity: 'misc',
        parent: parent_tag
      )

      children << temp_child
    end

    db_children = parent_tag.children.order(:id).to_a
    assert_equal children.length, db_children.length

    # checks that arrays have same contents
    (0..(children.length - 1)).each do |n|
      assert_operator children[n], :identical?, db_children[n]
    end
  end

  test 'can\'t create tags with ridiculously long fields' do
    really_long_string = ''
    really_long_string += ('a'.to_s * 300)

    test_tag = Tag.new(
      name: really_long_string,
      tag_type: 'detail',
      polarity: 'misc',
      synonym: nil,
      parent: nil
    )

    test_tag.validate

    assert_includes test_tag.errors[:name], 'is too long (maximum is 64 characters)'
  end

  test 'can\t create tags with types not in CardinalSettings' do
    test_tag = Tag.new(
      name: 'Some Uniquely Generic tag',
      tag_type: 'definitely invalid type',
      polarity: 'misc',
      synonym: nil,
      parent: nil
    )

    test_tag.validate

    assert_includes test_tag.errors[:tag_type], 'is not included in the list'
  end

  test 'cant create tags with the same lower field' do
    Tag.create!(
      name: 'My New Tag',
      polarity: 'misc',
      tag_type: 'detail',
      synonym: nil,
      parent: nil
    )

    dupe_tag = Tag.new(
      name: 'My New TAG',
      polarity: 'misc',
      tag_type: 'detail',
      synonym: nil,
      parent: nil
    )

    assert_raises ActiveRecord::RecordInvalid do
      dupe_tag.save!
    end
  end

  test 'Tag.find_or_create_with_downcase should correctly identify duplicates' do
    found_tag = nil

    assert_no_difference('Tag.count') do
      found_tag = Tag.find_or_create_with_downcase(
        polarity: @camel_case.polarity,
        tag_type: @camel_case.tag_type,
        name: 'CAMELCASE'
      )
    end

    assert_equal @camel_case.id, found_tag.id
  end
end
