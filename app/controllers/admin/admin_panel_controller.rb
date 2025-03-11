# frozen_string_literal: true

module Admin
  class AdminPanelController < ApplicationController
    include ApplicationHelper

    before_action :require_admin
    before_action :analytics

    def index; end

    def analytics
      @interval = params[:interval] || 'day'
      now = DateTime.now

      @begin_date = params[:date_from].present? ? DateTime.iso8601(params[:date_from]) : (now - 1.day)
      @end_date = params[:date_to].present? ? DateTime.iso8601(params[:date_to]) : now

      @range = @begin_date...@end_date

      @intervals = %w[1s 30s 90s 1m 5m 15m hour day week month quarter year]
      @report_analytics = [
        { name: 'New', data: Rollup.where(time: @range).series('Report creates', interval: @interval) },
        { name: 'Resolved', data: Rollup.where(time: @range).series('Report resolves', interval: @interval) }
      ]
      @user_analytics = [
        { name: 'Visited', data: Rollup.where(time: @range).series('User visits', interval: @interval) },
        { name: 'Registered', data: Rollup.where(time: @range).series('User registrations', interval: @interval) },
        { name: 'Deleted', data: Rollup.where(time: @range).series('User deletes', interval: @interval),
          interval: @interval }
      ]
      @prompt_analytics = [
        { name: 'New', data: Rollup.where(time: @range).series('Prompt creates', interval: @interval) },
        { name: 'Edits', data: Rollup.where(time: @range).series('Prompt edits', interval: @interval) },
        { name: 'Answers', data: Rollup.where(time: @range).series('Prompt answers', interval: @interval) },
        { name: 'Lucky Dipped', data: Rollup.where(time: @range).series('Lucky dips', interval: @interval) }
      ]
      @character_analytics = [
        { name: 'New', data: Rollup.where(time: @range).series('Character creates', interval: @interval) }
      ]
      @ticket_analytics = [
        { name: 'Used', data: Rollup.where(time: @range).series('Ticket used', interval: @interval) }
      ]
      @message_analytics = [
        { name: 'New', data: Rollup.where(time: @range).series('Message creates', interval: @interval) },
        { name: 'Edits', data: Rollup.where(time: @range).series('Message edits', interval: @interval) }
      ]
      @connect_code_analytics = [
        { name: 'New', data: Rollup.where(time: @range).series('ConnectCode creates', interval: @interval) },
        { name: 'Used', data: Rollup.where(time: @range).series('ConnectCode consumes', interval: @interval) }
      ]

      @tags = {}

      @tag_events = Ahoy::Event.where_event('Tag Popular').where(time: @range)

      @tag_events.each do |tag_event|
        tag_event.properties['tags'].each do |key, value|
          @tags[key] = if @tags.key?(key)
                         @tags[key] + value
                       else
                         value
                       end
        end
      end

      @tag_analytics = @tags
    end
  end
end
