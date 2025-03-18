# frozen_string_literal: true

require 'test_helper'

class PseudonymTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
    @user2 = users(:user_two)
    @user3 = users(:user_three)

    @pseudonym = pseudonyms(:user)
    @pseudonym2 = pseudonyms(:user_two)
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

  test 'should not create unentitled psueodnym' do
    assert_raises ActiveRecord::RecordInvalid do
      Pseudonym.create!(
        name: @pseudonym.name,
        user: @user2
      )
    end
  end

  test 'should create entitled psueodnym' do
    assert_nothing_raised do
      Pseudonym.create!(
        name: 'user_two2',
        user: @user2
      )
    end
  end

  test 'new psueodnym should create and associate entitlement' do
    assert_changes('@user3.entitlements.reload.count', 1) do
      assert_nothing_raised do
        Pseudonym.create!(
          name: 'user_three2',
          user: @user3
        )
      end
      pseudonym = Pseudonym.find_by(name: 'user_three2')
      entitlement = @user3.entitlements.last
      assert entitlement.flag == 'pseudonym'
      assert entitlement.data == 'user_three2'
      assert entitlement.object == pseudonym
    end
  end
end
