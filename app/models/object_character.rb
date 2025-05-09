# frozen_string_literal: true

class ObjectCharacter < ApplicationRecord
  belongs_to :object, polymorphic: true
  belongs_to :character

  validates :character_id, uniqueness: { scope: %i[object_id object_type] }
  validate :authorization, on: %i[create update]

  # This should be called by using the object_characters setter on a prompt
  # since we aren't setting Objectcharacter.prompt here
  # @return [Array<ObjectCharacter>]
  def self.from_character_params(character_params)
    characters = character_params.map { |c_id| Character.find(c_id) }

    # Let @prompt.save handle the bulk of processing/validating characters
    characters.map { |temp_character| ObjectCharacter.new(character: temp_character) }
  end

  private

  def authorization
    return unless object.user.id != character.user.id

    errors.add(:user, "You don't own this #{object_type} or Character.")
  end
end
