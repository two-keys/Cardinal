# frozen_string_literal: true

json.extract! ad, :id, :user_id, :image, :variant, :url, :impressions, :clicks, :created_at, :updated_at
json.url ad_url(ad, format: :json)
json.image url_for(ad.approved_image)
