# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'colorize'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end

  # run it as DEBUG=true rails test
  if ENV['DEBUG']
    Rails.logger = Logger.new($stdout)
    Rails.logger.level = Logger::INFO
    Rails.logger.datetime_format = ''
    Rails.logger.formatter = proc do |severity, time, _progname, msg|
      # "#{severity.green}: #{msg}\n"
      call_details = Kernel.caller[5].gsub(/#{Rails.root}/, '')
      call_details.match(/(.+):(.+):/)
      filename = ::Regexp.last_match(1)
      line = ::Regexp.last_match(2)
      length = 40
      filename = filename[-length, filename.length].to_s if filename.length >= length
      filename = filename.rjust(length + 2, '.')
      "[#{severity.green} #{time} #{filename.light_blue}:#{line.light_blue}] #{msg}\n"
    end

    # to see database queries
    # run it as DEBUG=db rails test
    ActiveRecord::Base.logger = ActiveSupport::Logger.new($stdout) if ENV['DEBUG'] == 'db'
  end

  # special output which works in debug
  def echo(msg)
    return unless ENV['DEBUG']

    puts msg.blue
  end
end
