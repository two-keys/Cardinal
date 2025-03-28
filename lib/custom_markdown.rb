# frozen_string_literal: true

class CardinalMarkdownRenderer < Redcarpet::Render::HTML
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::SanitizeHelper

  def paragraph(text)
    process_custom_tags("<p>#{text.gsub("\n", '<br/>')}</p>\n")
  end

  def list_item(text, _params)
    "<li>#{process_custom_tags(text)}</li>\n"
  end

  def header(text, header_level)
    "<h#{header_level}>#{process_custom_tags(text)}</h#{header_level}>\n"
  end

  def process_custom_tags(text)
    color_regex = /\?!([a-zA-Z0-9]{6})\|([^|]+)\|/
    matches = text.match(color_regex)
    matches ? colorize(matches[1], matches[2]) : text
  end

  def colorize(color, text)
    content_tag(:span, text, style: "color: ##{color};")
  end

  # rubocop:disable Rails/OutputSafety

  # A generic class method for site-wide, safe markdown.
  def self.generic_render(text)
    sanitized_text = ActionController::Base.helpers.sanitize(text, tags: %w[span br], attributes: %w[style])
    renderer = CardinalMarkdownRenderer.new(hard_wrap: true, link_attributes: { target: '_blank' })
    options = {
      autolink: true,
      fenced_code_blocks: true,
      lax_spacing: true,
      no_intra_emphasis: true,
      strikethrough: true,
      superscript: true,
      tables: true,
      quote: true,
      footnotes: true,
      space_after_headers: true
    }
    Redcarpet::Markdown.new(renderer, options).render(sanitized_text).html_safe
  end
  # rubocop:enable Rails/OutputSafety
end
