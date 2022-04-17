# frozen_string_literal: true

module PromptsHelper
  def readable_tag_type(tag_type)
    readable = tag_type.capitalize
    readable.gsub('_', ' ')
  end

  def default_entries_for(tag_type)
    CardinalSettings::Tags.types[tag_type]['entries'].map do |entry|
      {
        name: entry,
        checked: false
      }
    end
  end
end
