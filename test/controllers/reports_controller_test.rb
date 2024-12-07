# frozen_string_literal: true

require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    @user2 = users(:user_two)
    @user3 = users(:user_three)
    @user_banned = users(:user_banned)

    @prompt = prompts(:one)
    @prompt2 = prompts(:two)
    @prompt_john = prompts(:johns)

    # Present in chat_one, which contains user and user2
    @message = messages(:user)
    @message2 = messages(:user_two)

    # Present in chat_two, which contains user and user3
    @message3 = messages(:user_three)

    @character = characters(:one)
    @character2 = characters(:two)

    @report = reports(:reported_message)
  end

  test 'should report prompt' do
    sign_in @user
    assert_difference 'Report.count', 1 do
      post reports_url, params: { report: { reportable_id: @prompt_john.id, reportable_type: 'Prompt', rules: [1] } }
    end
    assert_redirected_to report_url(Report.last)
  end

  test 'should not report own prompt' do
    sign_in @user
    assert_no_difference 'Report.count' do
      post reports_url, params: { report: { reportable_id: @prompt.id, reportable_type: 'Prompt', rules: [1] } }
    end
    assert_response :unprocessable_entity
  end

  # I need to figure this one out later
  # test 'should report message' do
  #  sign_in @user2
  #  assert_difference 'Report.count', 1 do
  #    post reports_url, params: { report: { reportable_id: @message.id, reportable_type: 'Message', rules: [1] } }
  #  end
  #  assert_redirected_to report_url(Report.last)
  # end

  test 'should not report own message' do
    sign_in @user
    assert_no_difference 'Report.count' do
      post reports_url, params: { report: { reportable_id: @message.id, reportable_type: 'Message', rules: [1] } }
    end
    assert_response :missing
  end

  test 'should report character' do
    sign_in @user
    assert_difference 'Report.count', 1 do
      post reports_url,
           params: { report: { reportable_id: @character2.id, reportable_type: 'Character', rules: [1] } }
    end
    assert_redirected_to report_url(Report.last)
  end

  test 'should not report own character' do
    sign_in @user
    assert_no_difference 'Report.count' do
      post reports_url, params: { report: { reportable_id: @character.id, reportable_type: 'Character', rules: [1] } }
    end
    assert_response :unprocessable_entity
  end

  test 'should not report when banned' do
    sign_in @user_banned
    assert_no_difference 'Report.count' do
      post reports_url,
           params: { report: { reportable_id: @character2.id, reportable_type: 'Character', rules: [1] } }
    end
    assert_redirected_to new_user_session_path
  end

  test 'should not report when not logged in' do
    assert_no_difference 'Report.count' do
      post reports_url,
           params: { report: { reportable_id: @character2.id, reportable_type: 'Character', rules: [1] } }
    end
    assert_redirected_to new_user_session_path
  end

  test 'should get report page' do
    sign_in @user
    get report_url(@report)
    assert_response :success
  end

  test 'should not get report page when not logged in' do
    get report_url(@report)
    assert_redirected_to new_user_session_path
  end

  test 'should not get report page when banned' do
    sign_in @user_banned
    get report_url(@report)
    assert_redirected_to new_user_session_path
  end

  test 'should not get report page when not authorized' do
    sign_in @user2
    get report_url(@report)
    assert_response :missing
  end
end
