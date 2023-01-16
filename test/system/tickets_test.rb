# frozen_string_literal: true

require 'application_system_test_case'

class TicketsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @john = users(:john)
    @ticket = tickets(:johns)

    sign_in(@john)
  end

  test 'visiting the index' do
    visit tickets_url
    assert_selector 'h1', text: 'Tickets'
  end

  test 'should destroy ticket' do
    future = 1.day.from_now
    travel_to(future)

    visit ticket_url(@ticket)

    click_on 'Destroy this ticket', match: :first
    assert_text 'Ticket was successfully destroyed'
  end
end
