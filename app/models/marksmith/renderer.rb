# frozen_string_literal: true

require 'custom_markdown'

module Marksmith
  class Renderer
    def initialize(body:)
      @body = body
    end

    def render
      CardinalMarkdownRenderer.generic_render(@body)
    end
  end
end
