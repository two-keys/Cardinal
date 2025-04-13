# frozen_string_literal: true

require 'clockwork'
include Clockwork # rubocop:disable Style/MixinUsage

handler do |job|
  Rails.logger.debug "Running #{job}"
end

every(1.hour, 'AnalyticsJob.perform_later')
