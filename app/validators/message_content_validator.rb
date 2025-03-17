# frozen_string_literal: true

class MessageContentValidator < ActiveModel::Validator
  IMAGE_DATA_REGEX = /!\[(?<title>.*)\]\((?<data>data:.*)\)/

  def check_length(content)
    content_without_images = content.gsub(IMAGE_DATA_REGEX, '')
    local_errors = []

    if content_without_images.length > Message::MAX_CONTENT_LENGTH
      local_errors << "Message must be less than #{Prompt::MAX_CONTENT_LENGTH} characters"
    end

    local_errors
  end

  def validate(record)
    has_content = record.content.present?

    if has_content
      check_length(record.content).each do |error|
        record.errors.add(:content, error)
      end
    else
      record.errors.add :content, 'Message must not be empty'
    end
  end
end
