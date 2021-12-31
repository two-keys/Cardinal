class CardinalMarkdownRenderer < Redcarpet::Render::HTML
    include ActionView::Helpers::TagHelper

    def paragraph(text)
        process_custom_tags("<p>#{text.strip}</p>\n")
    end

    def process_custom_tags(document)
        # scans for multiple ?!color|text| tags and replaces them with a span tag
        # e.g. ?!ff0000|testing|
        document.gsub! /\?\!([a-zA-Z0-9]{6})\|([^\|]+)\|/ do |match|
            color_div($1, $2)
        end
        document
    end

    def color_div(color, text)
        content_tag(:span, text, style: "color: ##{color}")
    end
end
