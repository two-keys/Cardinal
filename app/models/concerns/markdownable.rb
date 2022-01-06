# frozen_string_literal: true

module Markdownable
  require 'custom_markdown'
  extend ActiveSupport::Concern

  def markdown_concern(text)
    CardinalMarkdownRenderer.generic_render(text)
  end
end
