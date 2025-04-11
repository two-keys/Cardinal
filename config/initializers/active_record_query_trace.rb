# frozen_string_literal: true

if Rails.env.development?
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.colorize = :yellow
  ActiveRecordQueryTrace.lines = 10
end
