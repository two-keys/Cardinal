# frozen_string_literal: true

module Markdownable
  require 'cardinal_markdown_renderer'
  extend ActiveSupport::Concern

  def markdown_concern(text)
    CardinalMarkdownRenderer.generic_render(text)
  end
end
