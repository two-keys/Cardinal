# frozen_string_literal: true

json.extract! use_page, :id, :title, :content, :created_at, :updated_at
json.url use_page_url(use_page, format: :json)
