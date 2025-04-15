# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class AlertTest < ActiveSupport::TestCase
  setup do
    @regex_alert = alerts(:one)
    @standard_alert = alerts(:two)
    @standard_replace = alerts(:three)

    @test_cases = [
      {
        model: prompts(:one),
        field: :ooc,
        value: 'hi i have foo text in my ooc'
      },
      {
        model: characters(:one),
        field: :description,
        value: 'i have foo text in my description, believe it or not'
      }
    ]
  end

  test 'should trigger on regex' do
    assert @regex_alert.condition('foo')
    assert @regex_alert.condition('bar')
  end

  test 'should replace on regex' do
    assert_equal 'baz', @regex_alert.transform('foo')
  end

  test 'should trigger on standard' do
    assert @standard_alert.condition('foo')
  end

  test 'should replace on standard' do
    assert_equal 'bar', @standard_replace.transform('foo')
  end

  test 'should not skip alert if general fields were changed' do
    @test_cases.each do |test_case|
      model = test_case[:model]
      model.send("#{test_case[:field]}=", test_case[:value])

      mock = Minitest::Mock.new
      mock.expect :send_discord_alert, true, [model, [@standard_replace.title, 'Regex']]

      ApplicationController.stub :helpers, mock do
        assert model.save
      end

      assert mock.verify
    end
  end

  test 'should not skip alert if mixed fields were changed' do
    @test_cases.each do |test_case|
      model = test_case[:model]
      model.tag_status = :dirty
      model.send("#{test_case[:field]}=", test_case[:value])

      mock = Minitest::Mock.new
      mock.expect :send_discord_alert, true, [model, [@standard_replace.title, 'Regex']]

      ApplicationController.stub :helpers, mock do
        assert model.save
      end

      assert mock.verify
    end
  end

  test 'should skip alert if only skippable fields were changed' do
    @test_cases.each do |test_case|
      model = test_case[:model]
      model.tag_status = :dirty

      # will (correctly) raise 'expects 0 arguments' if alert logic is broken
      mock = Minitest::Mock.new
      mock.expect :send_discord_alert, nil

      ApplicationController.stub :helpers, mock do
        assert model.save
      end

      assert_raises(MockExpectationError, 'Didn\'t raise MockExpectationError') { mock.verify }
    end
  end
end
