# frozen_string_literal: true

json.extract! filter, :group, :filter_type, :priority, :target_type, :target_id
json.url prompt_url(filter, format: :json)
