# frozen_string_literal: true

class ProcessTaggablesJob < ApplicationJob
  queue_as :default

  def perform
    batch_size = 1_000

    taggables = [Prompt]
    taggables.each do |model_class|
      model_class.where(
        tag_status: :dirty
      ).limit(batch_size).find_each(&:process_tags) # process_tags will undirtify
    end
  end
end
