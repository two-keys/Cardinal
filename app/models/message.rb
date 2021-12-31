# frozen_string_literal: true

class Message < ApplicationRecord
  include Markdownable

  belongs_to :chat
  belongs_to :user, optional: true

  validates :content, presence: true, length: { minimum: 10, maximum: 10_000 }

  def markdown
    markdown_concern(content)
  end
end
