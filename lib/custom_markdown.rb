# frozen_string_literal: true

class CardinalMarkdownRenderer < Redcarpet::Render::HTML
  include ActionView::Helpers::TagHelper

  def paragraph(text)
    process_custom_tags("<p>#{text.strip}</p>\n")
  end

  def process_custom_tags(document)
    # scans for multiple ?!color|text| tags and replaces them with a span tag
    # e.g. ?!ff0000|testing|
    document.gsub!(/\?!([a-zA-Z0-9]{6})\|([^|]+)\|/) do |_match|
      color_div(Regexp.last_match(1), Regexp.last_match(2))
    end
    document
  end

  def color_div(color, text)
    content_tag(:span, text, style: "color: ##{color}")
  end

  # rubocop:disable Rails/OutputSafety

  # A generic class method for site-wide, safe markdown.
  def self.generic_render(text)
    renderer = CardinalMarkdownRenderer.new(hard_wrap: true, filter_html: true,
                                            link_attributes: { target: '_blank' })
    options = {
      autolink: true,
      fenced_code_blocks: true,
      lax_spacing: true,
      no_intra_emphasis: true,
      strikethrough: true,
      superscript: true
    }
    Redcarpet::Markdown.new(renderer, options).render(text).html_safe
  end
  # rubocop:enable Rails/OutputSafety
end
