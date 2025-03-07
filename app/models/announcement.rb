# frozen_string_literal: true

class Announcement < ApplicationRecord
  include Markdownable
  include Auditable

  validates :title, presence: true
  validates :content, presence: true

  default_scope { order('created_at DESC') }

  def markdown
    markdown_concern(content)
  end
end
