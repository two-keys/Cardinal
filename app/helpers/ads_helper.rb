# frozen_string_literal: true

module AdsHelper
  def ads_for(variant, count)
    Ad.ads_for(variant, count, view: true)
  end
end
