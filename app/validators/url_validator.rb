# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    begin
      uri = URI.parse(value)
      resp = uri.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      resp = false
    end
    return if resp == true

    record.errors.add(attribute, (options[:message] || 'is not a valid url'))
  end
end
