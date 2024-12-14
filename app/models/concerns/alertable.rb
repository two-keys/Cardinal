# frozen_string_literal: true

module Alertable
  extend ActiveSupport::Concern

  included do
    around_save :send_alerts_and_replace

    def alertable_fields
      raise NotImplementedError
    end

    def send_alerts_and_replace
      triggered = []
      Alert.find_each do |alert|
        alertable_fields.each do |field|
          next unless alert.condition(send(field))

          triggered << alert.title
          send("#{field}=", alert.transform(send(field))) if alert.replacement
        end
      end

      triggered = triggered.uniq

      yield # Saves after this point, ID assigned

      return unless triggered.any?

      ApplicationController.helpers.send_discord_alert(self, triggered)
    end
  end
end
