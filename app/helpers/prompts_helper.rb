# frozen_string_literal: true

module PromptsHelper
  def readable_tag_type(tag_type)
    readable = tag_type.capitalize
    readable.gsub('_', ' ')
  end
end
