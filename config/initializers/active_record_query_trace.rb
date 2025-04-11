# frozen_string_literal: true

if Rails.env.development?
  ActiveRecordQueryTrace.enabled = ENV.fetch('QUERY_TRACE', 0).to_i == 1
  ActiveRecordQueryTrace.colorize = :yellow
  ActiveRecordQueryTrace.lines = ENV.fetch('QUERY_TRACE_LINES', 5).to_i
end
