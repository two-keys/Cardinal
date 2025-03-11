# frozen_string_literal: true

class AnalyticsJob < ApplicationJob
  queue_as :default

  def perform
    %w[1s 30s 90s 1m 5m 15m hour day week month quarter year].each do |interval| # rubocop:disable Metrics/BlockLength
      Ahoy::Visit.all.rollup('User visits', column: :started_at, interval: interval)
      Ahoy::Event.where(name: 'User Created').rollup('User registrations', column: :time, interval: interval)
      Ahoy::Event.where(name: 'User Deleted').rollup('User deletes', column: :time, interval: interval)

      Ahoy::Event.where(name: 'Prompt Lucky Dipped').rollup('Lucky dips', column: :time, interval: interval)
      Ahoy::Event.where(name: 'Prompt Created').rollup('Prompt creates', column: :time, interval: interval)
      Ahoy::Event.where(name: 'Prompt Edited').rollup('Prompt edits', column: :time, interval: interval)
      Ahoy::Event.where(name: 'Prompt Answered').rollup('Prompt answers', column: :time, interval: interval)

      Ahoy::Event.where(name: 'Tag Uses').rollup('Tag used', column: :time, interval: interval)
      @top_ten_tags = Tag.joins(:object_tags)
                         .where('"object_tags"."object_type" = ?', 'Prompt')
                         .group(:id)
                         .order('COUNT("tags"."id") DESC')
                         .select('COUNT("tags"."id"), "tags".*')
                         .limit(25)

      tags = {}

      @top_ten_tags.each do |tag|
        tags["#{tag.polarity}:#{tag.tag_type}:#{tag.lower}"] = tag.count
      end

      Ahoy.non_visit_track('Tag Popular',
                           visit_properties: { user_agent: 'Rails Job' },
                           event_properties: { tags: tags })

      Ahoy::Event.where(name: 'Character Created').rollup('Character creates', column: :time, interval: interval)

      Ahoy::Event.where(name: 'Tag Created').rollup('Tag creates', column: :time, interval: interval)
      Ahoy::Event.where(name: 'Tag Used').rollup('Tag uses', column: :time, interval: interval)

      Ahoy::Event.where(name: 'Ticket Created').rollup('Ticket used', column: :time, interval: interval)

      Ahoy::Event.where(name: 'Report Created').rollup('Report creates', column: :time, interval: interval)
      Ahoy::Event.where(name: 'Report Resolved').rollup('Report resolves', column: :time, interval: interval)

      Ahoy::Event.where(name: 'Message Created').rollup('Message creates', column: :time, interval: interval)
      Ahoy::Event.where(name: 'Message Edits').rollup('Message edits', column: :time, interval: interval)

      Ahoy::Event.where(name: 'ConnectCode Created').rollup('ConnectCode creates', column: :time, interval: interval)
      Ahoy::Event.where(name: 'ConnectCode Consumed').rollup('ConnectCode consumes', column: :time, interval: interval)
    end
  end
end
