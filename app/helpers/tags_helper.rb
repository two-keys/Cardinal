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

  def tag_display(schema: TagSchema, tag_type: nil, names: [])
    entries = schema.entries_for(tag_type)
    fill_ins = []

    # logger.debug "#{polarity} #{tag_type}"
    checkboxes = entries.map do |entry|
      {
        name: entry,
        checked: names.include?(entry)
      }
    end

    fill_ins = (names - entries) if TagSchema.fillable?(tag_type)

    { checkboxes:, fill_ins: }
  end
end
