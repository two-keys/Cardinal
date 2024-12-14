# frozen_string_literal: true

json.array! @alerts, partial: 'alerts/alert', as: :alert
