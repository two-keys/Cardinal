# frozen_string_literal: true

class PromptTag < ApplicationRecord
  belongs_to :prompt
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :prompt_id }

  # This should be called by using the prompt_tags setter on a prompt, since we aren't setting PromptTag.prompt here
  # @return [Array<PromptTag>]
  def self.from_tag_params(tag_params)
    new_prompt_tags = []
    tag_params.each do |polarity, param_types|
      # for each polarity
      param_types.each do |type, param_tags|
        # for each tag type under each polarity

        param_tags.select(&:present?).each do |tag_name|
          temp_prompt_tag = Tag.find_or_create_by!(name: tag_name, tag_type: type, polarity: polarity)
          new_prompt_tags << PromptTag.new(tag: temp_prompt_tag)
        end
      end
    end

    # Let @prompt.save handle the bulk of processing/validating tags
    # The only thing we should worry about here is not passing duplicate tags
    new_prompt_tags.uniq { |pt| pt.tag.id }
  end
end
