# frozen_string_literal: true

class PromptContentValidator < ActiveModel::Validator
  def check_content(id, content)
    local_errors = []

    if content.length < Prompt::MIN_CONTENT_LENGTH
      local_errors << "Content must be greater than #{Prompt::MIN_CONTENT_LENGTH} characters"
    end

    matches_found = Prompt.where.not(id: id).and(
      Prompt.where(ooc: content).or(
        Prompt.where(starter: content)
      )
    ).count
    local_errors << 'Duplicate content found' if matches_found.positive?

    local_errors
  end

  def validate(record)
    has_ooc = record.ooc.present?
    has_starter = record.starter.present?

    if has_ooc || has_starter
      if has_ooc
        check_content(record.id, record.ooc).each do |error|
          record.errors.add(:ooc, error)
        end
      end

      if has_starter
        check_content(record.id, record.starter).each do |error|
          record.errors.add(:starter, error)
        end
      end
    else
      record.errors.add :starter, 'You must have either a starter or an ooc set.'
    end
  end
end
