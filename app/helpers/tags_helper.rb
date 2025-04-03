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

  def tag_display(schema: TagSchema, polarity: nil, tag_type: nil, names: [])
    checkboxes = []
    fill_ins = []

    logger.debug tag_type
    schema.entries_for(tag_type).each do |entry|
      checkboxes << {
        name: entry,
        checked: names.include?(entry)
      }
    end

    fill_ins = (names - checkboxes.pluck(:name)) if TagSchema.fillable?(tag_type)

    { checkboxes:, fill_ins: }
  end
end
