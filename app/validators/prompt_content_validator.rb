# frozen_string_literal: true

class PromptContentValidator < ActiveModel::Validator
  def check_length(content)
    local_errors = []

    if content.length < Prompt::MIN_CONTENT_LENGTH
      local_errors << "Combined content must be greater than #{Prompt::MIN_CONTENT_LENGTH} characters"
    end

    if content.length > Prompt::MAX_CONTENT_LENGTH
      local_errors << "Combined content must be less than #{Prompt::MAX_CONTENT_LENGTH} characters"
    end

    local_errors
  end

  def check_duplicity(id, content)
    local_errors = []

    matches_found = Prompt.where.not(id:).and(
      Prompt.where(ooc: content).or(
        Prompt.where(starter: content)
      )
    ).count
    local_errors << 'Duplicate content found' if matches_found.positive?

    local_errors
  end

  def validate(record) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    has_ooc = record.ooc.present?
    has_starter = record.starter.present?

    if has_ooc || has_starter
      if has_ooc
        check_duplicity(record.id, record.ooc).each do |error|
          record.errors.add(:ooc, error)
        end
      end

      if has_starter
        check_duplicity(record.id, record.starter).each do |error|
          record.errors.add(:starter, error)
        end
      end

      full_content = ''
      full_content = (full_content + record.ooc) if record.ooc.present?
      full_content = (full_content + record.starter) if record.starter.present?

      Rails.logger.debug full_content.length

      check_length(full_content).each do |error|
        record.errors.add(:ooc, error) if has_ooc
        record.errors.add(:starter, error) if has_starter
      end
    else
      record.errors.add :starter, 'You must have either a starter or an ooc set.'
    end
  end
end
