# frozen_string_literal: true

require 'clockwork'
require 'active_support/time' # Allow numeric durations (eg: 1.minutes)
require './config/boot'
require './config/environment'

module Clockwork
  every(5.minutes, 'analytics.refresh') { AnalyticsJob.perform_later }
  every(10.minutes, 'subscribers.refresh') { SubscriptionRenewalsJob.perform_later }
end
