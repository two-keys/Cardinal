# frozen_string_literal: true

class PromptTag < ApplicationRecord
  belongs_to :prompt
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :prompt_id }

  # This should be called by using the prompt_tags setter on a prompt, since we aren't setting PromptTag.prompt here
  # @return [Array<PromptTag>]
  def self.from_tag_params(tag_params)
    new_prompt_tags = []

    tags = Tag.from_tag_params(tag_params)

    tags.each do |temp_tag|
      new_prompt_tags << PromptTag.new(tag: temp_tag)
    end

    # Let @prompt.save handle the bulk of processing/validating tags
    new_prompt_tags
  end
end
