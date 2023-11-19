# frozen_string_literal: true

require 'test_helper'

class PseudonymTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
    @user2 = users(:user_two)

    @pseudonym = pseudonyms(:user)
  end

  test "can only create #{Ticket::MAX_PER_DAY}" do
    (1..Ticket::MAX_PER_DAY).each do |n|
      assert_nothing_raised do
        Pseudonym.create!(
          name: "slimmy#{'1' * n}",
          status: 'posted',
          user: @user
        )
      end
    end

    assert_raises ActiveRecord::RecordInvalid do
      Pseudonym.create!(
        name: 'testname',
        user: @user
      )
    end
  end

  test 'should only create unique pseudonyms' do
    assert_raises ActiveRecord::RecordInvalid do
      Pseudonym.create!(
        name: @pseudonym.name,
        user: @user
      )
    end

    assert_raises ActiveRecord::RecordInvalid do
      Pseudonym.create!(
        name: @pseudonym.name,
        user: @user2
      )
    end
  end
end
