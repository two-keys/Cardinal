# frozen_string_literal: true

json.extract! filter, :group, :filter_type, :priority
json.tag do
  json.extract! filter.tag, :polarity, :tag_type, :name
end
json.url prompt_url(filter, format: :json)
