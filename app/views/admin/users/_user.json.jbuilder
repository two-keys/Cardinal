# frozen_string_literal: true

json.extract! user, :id, :username, :email, :created_at, :updated_at
json.url admin_user_path(user, format: :json)
