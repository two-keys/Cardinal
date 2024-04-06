# frozen_string_literal: true

class ObjectCharacter < ApplicationRecord
  belongs_to :object, polymorphic: true
  belongs_to :character

  validates :character_id, uniqueness: { scope: %i[object_id object_type] }

  # This should be called by using the object_characters setter on a prompt, since we aren't setting Objectcharacter.prompt here
  # @return [Array<Objectcharacter>]
  def self.from_character_params(character_params)
    new_object_characters = []

    characters = character_params.map { |c_id| Character.find(c_id) }

    characters.each do |temp_character|
      new_object_characters << ObjectCharacter.new(character: temp_character)
    end

    # Let @prompt.save handle the bulk of processing/validating characters
    new_object_characters
  end
end
