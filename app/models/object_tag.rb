# frozen_string_literal: true

class ObjectTag < ApplicationRecord
  belongs_to :object, polymorphic: true
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: %i[object_id object_type] }

  # This should be called by using the object_tags setter on a prompt, since we aren't setting ObjectTag.prompt here
  # @return [Array<ObjectTag>]
  def self.from_tag_params(tag_params)
    new_object_tags = []

    tags = Tag.from_tag_params(tag_params)

    tags.each do |temp_tag|
      new_object_tags << ObjectTag.new(tag: temp_tag)
    end

    # Let @prompt.save handle the bulk of processing/validating tags
    new_object_tags
  end
end
