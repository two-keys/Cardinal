# frozen_string_literal: true

json.extract! alert, :id, :title, :find, :regex, :replacement, :created_at, :updated_at
json.url admin_alert_url(alert, format: :json)
