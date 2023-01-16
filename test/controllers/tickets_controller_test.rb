# frozen_string_literal: true

require 'test_helper'

class TicketsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)

    @john = users(:john)
    @ticket = tickets(:johns)
  end

  test 'should get index' do
    sign_in(@user)
    get tickets_url
    assert_response :success
  end

  test 'should get index with ticket search' do
    skip 'Should add this when we have searchable tickets'

    sign_in(@user)
    get tickets_url
    assert_response :success
  end

  test 'should show ticket' do
    sign_in(@john)
    get ticket_url(@ticket)
    assert_response :success
  end

  test 'should destroy ticket' do
    sign_in(@john)

    future = DateTime.now + 1.day
    travel_to(future)

    assert_difference('Ticket.count', -1) do
      delete ticket_url(@ticket)
    end

    assert_redirected_to tickets_path
  end

  test 'should not destroy new ticket' do
    sign_in(@john)
    assert_no_difference 'Ticket.count' do
      delete ticket_url(@ticket)
    end

    assert_response :missing
  end

  test 'should not destroy ticket user doesn\'t own' do
    sign_in(@user)
    assert_no_difference 'Ticket.count' do
      delete ticket_url(@ticket)
    end

    assert_response :missing
  end
end
