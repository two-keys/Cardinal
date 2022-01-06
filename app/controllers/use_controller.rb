# frozen_string_literal: true

class UseController < ApplicationController
  include CardinalSettings
  require 'custom_markdown'
  require 'redcarpet'
  require 'redcarpet/render_strip'

  # GET /use/:page, defaulting to page: index
  # If the page has entries, the view will automatically display them
  def show
    unless Use.pages.keys.include?(params[:page])
      redirect_to use_page_path
      return
    end

    page = Use.get_page(params[:page])

    @links = Use.pages.keys
    @markdown = CardinalMarkdownRenderer.generic_render(page['markdown'])
    @entries = []
    stripped = []

    return unless page.key?('entries')

    page['entries'].each do |entry|
      @entries << CardinalMarkdownRenderer.generic_render(entry)

      md = Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
      stripped << md.render(entry)
    end

    respond_to do |format|
      format.html { render :show, status: :ok }
      format.json { render json: stripped, status: :ok }
    end
  end
end
