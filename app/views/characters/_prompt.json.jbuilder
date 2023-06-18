# frozen_string_literal: true

json.extract! character, :id, :description, :created_at, :updated_at
json.url character_url(character, format: :json)
