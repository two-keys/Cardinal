# frozen_string_literal: true

json.extract! ip_ban, :id, :title, :context, :addr, :created_at, :updated_at
json.url admin_ip_ban_url(ip_ban, format: :json)
