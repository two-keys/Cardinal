# frozen_string_literal: true

json.array! @filters, partial: 'filters/filter', as: :filter
