# frozen_string_literal: true

class Announcement < ApplicationRecord
  require 'custom_markdown'

  validates :title, presence: true
  validates :content, presence: true

  default_scope { order('created_at DESC') }

  def markdown
    renderer = CardinalMarkdownRenderer.new(hard_wrap: true, filter_html: true, link_attributes: { target: "_blank" })
    options = {
      autolink: true,
      fenced_code_blocks: true,
      lax_spacing: true,
      no_intra_emphasis: true,
      strikethrough: true,
      superscript: true
    }
    Redcarpet::Markdown.new(renderer, options).render(content).html_safe
  end
end
