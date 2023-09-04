# frozen_string_literal: true

json.extract! prompt, :id, :ooc, :starter, :created_at, :updated_at, :managed
json.url prompt_url(prompt, format: :json)
