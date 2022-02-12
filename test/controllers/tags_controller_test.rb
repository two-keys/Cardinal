# frozen_string_literal: true

require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @user2 = users(:user_two)
    @admin = users(:admin)

    @capital = tags(:capital)

    # Array of (Tag::MAX_SYNONYM_DEPTH + 2) Tags
    @generic_tags = []
    (0..(Tag::MAX_SYNONYM_DEPTH + 1)).each do |n|
      temp = tags(:generic)

      # Generate a copy so as to not mutate original
      new_tag = Tag.new(
        name: "#{temp.name} with rank #{n}",
        tag_type: temp.tag_type,
        polarity: temp.polarity,
        synonym: nil,
        parent: nil
      )

      # Add parent if we're not rank 0.
      new_tag.synonym = @generic_tags[n - 1] unless n.zero?

      new_tag.save

      @generic_tags << new_tag
    end
  end

  test 'should get index' do
    sign_in(@user)
    get tags_url
    assert_response :success
  end

  test 'should get new' do
    sign_in(@admin)
    get new_tag_url
    assert_response :success
  end

  test 'should not get new' do
    sign_in(@user)
    get new_tag_url
    assert_redirected_to root_url
  end

  test 'should show tag' do
    sign_in(@user)
    get tag_url(@capital)
    assert_response :success
  end

  test 'should get edit' do
    sign_in(@admin)
    get edit_tag_url @capital
    assert_response :success
  end

  test 'should not get edit' do
    sign_in(@user)
    get edit_tag_url @capital
    assert_redirected_to root_url
  end

  test 'should create tag' do
    sign_in(@admin)
    assert_difference('Tag.count') do
      post tags_url, params: {
        tag: { name: 'new tag', tag_type: 'misc', polarity: 'misc' },
        parent: { name: '', tag_type: '' }, synonym: { name: '', tag_type: '' }
      }
    end

    assert_redirected_to tag_url(Tag.where(name: 'new tag')[0])
    tag = Tag.find_by(name: 'new tag')

    assert_nil tag.parent
    assert_nil tag.synonym
  end

  test 'should create tag with ONLY parent' do
    sign_in(@admin)
    assert_difference('Tag.count', 2) do
      post tags_url, params: {
        tag: { name: 'new tag', tag_type: @capital.tag_type, polarity: @capital.polarity },
        parent: { name: 'new parent', tag_type: 'misc', polarity: 'misc' },
        synonym: { name: '', tag_type: '', polarity: '' }
      }
    end

    assert_redirected_to tag_url(Tag.where(name: 'new tag')[0])
    tag = Tag.find_by(name: 'new tag')

    assert_not_nil tag.parent
    assert_nil tag.synonym
  end

  test 'should create tag with ONLY synonym' do
    sign_in(@admin)
    assert_difference('Tag.count', 2) do
      post tags_url, params: {
        tag: { name: 'new tag', tag_type: @capital.tag_type, polarity: @capital.polarity },
        parent: { name: '', tag_type: '', polarity: '' },
        synonym: { name: 'new parent', tag_type: 'misc', polarity: 'misc' }
      }
    end

    assert_redirected_to tag_url(Tag.where(name: 'new tag')[0])
    tag = Tag.find_by(name: 'new tag')

    assert_nil tag.parent
    assert_not_nil tag.synonym
  end

  test 'should not create tag' do
    sign_in(@user)
    assert_no_difference('Tag.count') do
      post tags_url, params: { tag: { name: @capital.name, tag_type: @capital.tag_type } }
    end

    assert_redirected_to root_url
  end

  test 'should update tag' do
    sign_in(@admin)
    patch tag_url(@capital), params: {
      tag: { name: @capital.name, tag_type: @capital.tag_type },
      parent: { name: '', tag_type: '' }, synonym: { name: '', tag_type: '' }
    }
    assert_redirected_to tag_url(@capital)

    tag = Tag.find_by(name: @capital.name)

    assert_nil tag.parent
    assert_nil tag.synonym
  end

  test 'should update tag with parent' do
    sign_in(@admin)
    patch tag_url(@capital), params: {
      tag: { name: @capital.name, tag_type: @capital.tag_type },
      parent: { name: 'Country', tag_type: 'misc', polarity: 'misc' }, synonym: { name: '', tag_type: '', polarity: '' }
    }
    assert_redirected_to tag_url(@capital)

    tag = Tag.find_by(name: @capital.name)

    assert_not_nil tag.parent
    assert_nil tag.synonym
  end

  test 'should update tag with synonym' do
    sign_in(@admin)
    patch tag_url(@capital), params: {
      tag: { name: @capital.name, tag_type: @capital.tag_type },
      parent: { name: '', tag_type: '' }, synonym: { name: 'St. Louis', tag_type: 'misc', polarity: 'misc' }
    }
    assert_redirected_to tag_url(@capital)

    tag = Tag.find_by(name: @capital.name)

    assert_nil tag.parent
    assert_not_nil tag.synonym
  end

  test 'should not update tag' do
    sign_in(@user)
    patch tag_url(@capital), params: {
      tag: { name: @capital.name, tag_type: @capital.tag_type, polarity: @capital.polarity }
    }
    assert_redirected_to root_url
  end

  test 'should destroy tag' do
    sign_in(@admin)
    assert_difference('Tag.count', -1) do
      delete tag_url(@capital)
    end

    assert_redirected_to tags_url
  end

  test 'should not destroy tag' do
    sign_in(@user)
    assert_no_difference('Tag.count') do
      delete tag_url(@capital)
    end

    assert_redirected_to root_url
  end
end
