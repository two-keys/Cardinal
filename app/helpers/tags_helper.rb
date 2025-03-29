# frozen_string_literal: true

module TagsHelper
  def default_entries_for(tag_type)
    TagSchema.entries_for(tag_type).map do |entry|
      {
        name: entry,
        checked: false
      }
    end
  end
end
