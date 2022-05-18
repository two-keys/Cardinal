# frozen_string_literal: true

require 'test_helper'

class TicketTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
    @prompt = prompts(:one)

    @john = users(:john)
    @johns_prompt = prompts(:johns)
    @johns_ticket = tickets(:johns)
  end

  test 'ticket user must match item user' do
    assert_raises ActiveRecord::RecordInvalid do
      Ticket.create!(
        user: @user, item: @johns_prompt
      )
    end
  end

  test "a user can only spend #{Ticket::MAX_PER_DAY} tickets a day" do
    assert_equal Ticket::MAX_PER_DAY, Ticket.remaining(@user)

    (1..Ticket::MAX_PER_DAY).each do
      assert Ticket.create!(
        user: @user, item: @prompt
      )
    end

    assert_equal 0, Ticket.remaining(@user)

    assert_raises ActiveRecord::RecordInvalid do
      Ticket.create!(
        user: @user, item: @prompt
      )
    end
  end

  test 'deleting a prompt doesnt delete its ticket' do
    rem = Ticket.remaining(@john)
    assert_operator rem, '<', Ticket::MAX_PER_DAY

    assert_not_nil @johns_ticket.item
    @johns_prompt.destroy

    assert_not @johns_ticket.destroyed?
    @johns_ticket.reload
    assert_nil @johns_ticket.item
  end
end
