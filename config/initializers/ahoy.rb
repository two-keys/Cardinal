# frozen_string_literal: true

module Ahoy
  class Store < Ahoy::DatabaseStore
  end

  def self.non_visit_track(event_name, visit_properties: {}, event_properties: {})
    visitor = Ahoy::Visit.create(visit_properties)
    visitor.events.create(name: event_name, time: Time.zone.now, properties: event_properties)
  end
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false
