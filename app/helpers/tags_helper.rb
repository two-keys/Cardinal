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

  # mostly used for filters/simple page
  # see Taggable#entries_for & Taggable#fill_ins_for
  def tag_display(schema: TagSchema, tag_type: nil, tags: [])
    entries = schema.entries_for(tag_type)
    fill_ins = []

    # logger.debug "#{polarity} #{tag_type}"
    checkboxes = entries.map do |entry|
      {
        name: entry,
        checked: tags.any? { |tag| tag.first == entry }
      }
    end

    fill_ins = tags.select { |tag| entries.none? { |entry| tag.first == entry } } if TagSchema.fillable?(tag_type)

    { checkboxes:, fill_ins: }
  end
end
