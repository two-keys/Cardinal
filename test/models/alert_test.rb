# frozen_string_literal: true

require 'test_helper'

class AlertTest < ActiveSupport::TestCase
  setup do
    @regex_alert = alerts(:one)
    @standard_alert = alerts(:two)
    @standard_replace = alerts(:three)
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
end
