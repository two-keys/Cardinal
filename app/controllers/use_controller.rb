# frozen_string_literal: true

class UseController < ApplicationController
  include CardinalSettings
  require 'custom_markdown'

  # GET /use/:page, defaulting to page: index
  # If the page has entries, the view will automatically display them
  def show
    unless Use.pages.keys.include?(params[:page])
      redirect_to use_page_path
      return
    end

    page = Use.get_page(params[:page])
    @markdown = CardinalMarkdownRenderer.generic_render(page['markdown'])
    @entries = []

    return unless page.key?('entries')

    page['entries'].each do |entry|
      @entries << CardinalMarkdownRenderer.generic_render(entry)
    end
  end
end
