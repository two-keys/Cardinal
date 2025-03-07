# frozen_string_literal: true

class Alert < ApplicationRecord
  include Auditable

  def condition(value)
    return false if value.nil?
    return true if regex && Regexp.new(find).match?(value)
    return true if value.include?(find)

    false
  end

  def transform(value)
    return value if value.nil?
    return value.gsub(Regexp.new(find), replacement) if regex && !replacement.nil?
    return value.gsub(find, replacement) unless replacement.nil?

    value
  end
end
