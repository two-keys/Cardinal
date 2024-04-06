# frozen_string_literal: true

module Characterized
  extend ActiveSupport::Concern

  def add_characters(character_params)
    # We want to store a copy of the old characters
    old_characters = characters.map do |old_character|
      old_character
    end

    filtered_character_ids = character_params.select { |char| char.to_i >= 0 }

    begin
      self.object_characters = ObjectCharacter
                               .from_character_params(filtered_character_ids) # RecordInvalid thrown here
      # polymorphic relations are weird, so we have to reload for the above to take effect

      # logger.debug(object_characters.map { |v| "test #{v.character.name}" })
      # logger.debug characters.pluck(:name)
    rescue ActiveRecord::RecordInvalid
      self.characters = old_characters
      return false
    end

    true
  end
end
