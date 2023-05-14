# frozen_string_literal: true

class CharacterContentValidator < ActiveModel::Validator
  def check_content(id, content)
    local_errors = []

    if content.length < Character::MIN_CONTENT_LENGTH
      local_errors << "Content must be greater than #{Character::MIN_CONTENT_LENGTH} characters"
    end

    matches_found = Character.where.not(id:).and(
      Character.where(description: content)
    ).count
    local_errors << 'Duplicate content found' if matches_found.positive?

    local_errors
  end

  def validate(record)
    has_description = record.description.present?

    if has_description
      check_content(record.id, record.description).each do |error|
        record.errors.add(:description, error)
      end
    else
      record.errors.add :description, 'You must have a description set.'
    end
  end
end
