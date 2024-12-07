# frozen_string_literal: true

require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  setup do
    @prompt = prompts(:one)
    @chat = chats(:chat_one)
    @character = characters(:two)
    @reporter = users(:user)
    @reportee = users(:user_two)
  end

  test 'should create a report for prompt' do
    assert_nothing_raised do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end
  end

  test 'should create a report for chat' do
    assert_nothing_raised do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @chat
      )
    end
  end

  test 'should create a report for character' do
    assert_nothing_raised do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @character
      )
    end
  end

  test 'should not create a report without a reporter' do
    assert_raises ActiveRecord::RecordInvalid do
      Report.create!(
        rules: [1],
        reportee: @reportee,
        reportable: @prompt
      )
    end
  end

  test 'should not create a report without a rule' do
    assert_raises ActiveRecord::RecordInvalid do
      Report.create!(
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end
  end

  test 'should not create a report with invalid rule' do
    assert_raises ActiveRecord::RecordInvalid do
      Report.create!(
        rules: [0],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end
  end

  test 'should not create a report on self' do
    assert_raises ActiveRecord::RecordInvalid do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reporter,
        reportable: @prompt
      )
    end
  end

  test 'should create a report on the same reportable from different users' do
    assert_nothing_raised do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end

    assert_nothing_raised do
      Report.create!(
        rules: [1],
        reporter: @reportee,
        reportee: @reporter,
        reportable: @prompt
      )
    end
  end

  test 'should not create a report on the same reportable' do
    assert_nothing_raised do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end

    assert_raises ActiveRecord::RecordInvalid do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end
  end

  test 'should create a report on the same reportable after it has been handled' do
    assert_nothing_raised do
      Report.create!(
        rules: [1],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end

    report = Report.last
    report.handled = true
    report.save

    assert_nothing_raised do
      Report.create!(
        rules: [2],
        reporter: @reporter,
        reportee: @reportee,
        reportable: @prompt
      )
    end
  end
end
