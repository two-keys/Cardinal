# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class SearchTest < ActiveSupport::TestCase
  setup do
    @unrelated_user = users(:user)
    @user = User.create!(
      email: 'test@emal.com',
      password:
      'password',
      username: 'dummy',
      verified: true
    )

    @blockable_prompt = Prompt.create!(
      ooc: 'this is a testing prompt for searchtest', user: @unrelated_user, status: 'posted'
    )
    @blockable = Tag.create!(
      polarity: 'misc',
      tag_type: 'detail',
      name: 'Romancelike'
    )
    @blockable_prompt.tags << @blockable
    @exceptable = Tag.create!(polarity: 'meta', tag_type: 'genre', name: 'Action')
    @blockable_prompt.tags << @exceptable

    Filter.create!(user: @user, target: @blockable, filter_type: 'Rejection')

    Filter.create!(user: @unrelated_user, target: @blockable, filter_type: 'Exception', priority: 99)
  end

  test 'Filter should remove blocked tags' do
    search = SearchHelper.filter_query(
      Prompt.where(status: 'posted'),
      @user,
      Prompt,
      true
    )

    assert_includes @blockable_prompt.tags.pluck(:name), @blockable.name

    assert_not_includes search.pluck(:ooc), @blockable_prompt.ooc
  end

  test 'should not see blocked tag in search' do
    Prompt.stub :accessible_by, Prompt.where(status: 'posted') do
      search = SearchHelper.add_search(Prompt, @user, nil, {}, true)

      # flunk search.pluck(:ooc)
      # flunk Prompt.accessible_by.pluck(:ooc)
      assert_not_includes search.pluck(:ooc), @blockable_prompt.ooc
    end
  end

  test 'Filter should remove blocked tag even if someone elses exception overrides it' do
    search = SearchHelper.filter_query(
      Prompt.where(status: 'posted'),
      @user,
      Prompt,
      true
    )

    assert_includes @blockable_prompt.tags.pluck(:name), @blockable.name

    assert_not_includes search.pluck(:ooc), @blockable_prompt.ooc
  end

  test 'should not see blocked tag in search even if someone elses exception overrides it' do
    Prompt.stub :accessible_by, Prompt.where(status: 'posted') do
      search = SearchHelper.add_search(Prompt, @user, nil, {}, true)

      # flunk search.pluck(:ooc)
      # flunk Prompt.accessible_by.pluck(:ooc)
      # flunk search.to_sql
      assert_not_includes search.pluck(:ooc), @blockable_prompt.ooc
    end
  end

  test 'Filter should not remove blocked tag if your exception overrides it' do
    Filter.create!(user: @user, target: @exceptable, filter_type: 'Exception', priority: 99)

    search = SearchHelper.filter_query(
      Prompt.where(status: 'posted'),
      @user,
      Prompt,
      true
    )

    assert_includes @blockable_prompt.tags.pluck(:name), @blockable.name
    assert_includes @blockable_prompt.tags.pluck(:name), @exceptable.name

    assert_includes search.pluck(:ooc), @blockable_prompt.ooc
  end

  test 'should not remove blocked tag in search if your exception overrides it' do
    Filter.create!(user: @user, target: @exceptable, filter_type: 'Exception', priority: 99)

    Prompt.stub :accessible_by, Prompt.where(status: 'posted') do
      search = SearchHelper.add_search(Prompt, @user, nil, {}, true)

      # flunk search.pluck(:ooc)
      # flunk Prompt.accessible_by.pluck(:ooc)
      # flunk search.to_sql
      assert_includes search.pluck(:ooc), @blockable_prompt.ooc
    end
  end
end
