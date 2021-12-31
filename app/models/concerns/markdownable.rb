module Markdownable
    require 'custom_markdown'
    extend ActiveSupport::Concern

    def markdown_concern(text)
        renderer = CardinalMarkdownRenderer.new(hard_wrap: true, filter_html: true, link_attributes: { target: "_blank" })
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
end
