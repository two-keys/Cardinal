json.extract! announcement, :id, :title, :content, :created_at, :updated_at
json.url announcement_url(announcement, format: :json)
