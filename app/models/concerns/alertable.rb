# frozen_string_literal: true

module Alertable
  extend ActiveSupport::Concern

  included do
    around_save :send_alerts_and_replace

    def alertable_fields
      raise NotImplementedError
    end

    def send_alerts_and_replace
      # skip unless we have at least one alertable_field being changed
      alertable_changes = (alertable_fields & changed_attributes.keys.map(&:to_sym))
      has_alertable_changes = alertable_changes.length.positive?
      # Rails.logger.info({ changed: changed_attributes.keys.map(&:to_sym), alertable: alertable_fields })
      Rails.logger.info("Has alertable? #{has_alertable_changes}")
      unless has_alertable_changes
        yield
        return
      end

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
