# frozen_string_literal: true

class AnalyticsJob < ApplicationJob
  queue_as :default

  def perform
    Ahoy::Visit.all.rollup('User visits', column: :started_at)
    Ahoy::Event.where(name: 'User Created').rollup('User registrations', column: :time)
    Ahoy::Event.where(name: 'User Deleted').rollup('User deletes', column: :time)

    Ahoy::Event.where(name: 'Prompt Lucky Dipped').rollup('Lucky dips', column: :time)
    Ahoy::Event.where(name: 'Prompt Created').rollup('Prompt creates', column: :time)
    Ahoy::Event.where(name: 'Prompt Edited').rollup('Prompt edits', column: :time)
    Ahoy::Event.where(name: 'Prompt Answered').rollup('Prompt answers', column: :time)

    Ahoy::Event.where(name: 'Character Created').rollup('Character creates', column: :time)

    Ahoy::Event.where(name: 'Tag Created').rollup('Tag creates', column: :time)
    Ahoy::Event.where(name: 'Tag Used').rollup('Tag uses', column: :time)

    Ahoy::Event.where(name: 'Ticket Created').rollup('Ticket used', column: :time)

    Ahoy::Event.where(name: 'Report Created').rollup('Report creates', column: :time)
    Ahoy::Event.where(name: 'Report Resolved').rollup('Report resolves', column: :time)

    Ahoy::Event.where(name: 'Message Created').rollup('Message creates', column: :time)
    Ahoy::Event.where(name: 'Message Edits').rollup('Message edits', column: :time)

    Ahoy::Event.where(name: 'ConnectCode Created').rollup('ConnectCode creates', column: :time)
    Ahoy::Event.where(name: 'ConnectCode Consumed').rollup('ConnectCode consumes', column: :time)
  end
end
