# frozen_string_literal: true

require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)

    @test_tag = tags(:tagfordupefilters)
  end

  test 'should not allow duplicate tag in the same filter group' do
    Filter.create(user: @user, tag: @test_tag, group: 'First Group', filter_type: 'Rejection')

    assert_raises ActiveRecord::RecordInvalid do
      Filter.create!(user: @user, tag: @test_tag, group: 'First Group', filter_type: 'Rejection')
    end
  end

  test 'should allow duplicate tag in separate filter groups' do
    Filter.create(user: @user, tag: @test_tag, group: 'First Group', filter_type: 'Rejection')

    Filter.create!(user: @user, tag: @test_tag, group: 'Second Group', filter_type: 'Rejection')
  end
end
