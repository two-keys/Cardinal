# frozen_string_literal: true

module Admin
  class AdminPanelController < ApplicationController
    include ApplicationHelper

    before_action :require_admin
    before_action :analytics

    def index; end

    def analytics
      @report_analytics = [
        { name: 'New', data: Rollup.series('Report creates') }
      ]
      @user_analytics = [
        { name: 'Visited', data: Rollup.series('User visited') },
        { name: 'Registered', data: Rollup.series('User registrations') },
        { name: 'Deleted', data: Rollup.series('User deletes') }
      ]
      @prompt_analytics = [
        { name: 'New', data: Rollup.series('Prompt creates') },
        { name: 'Edits', data: Rollup.series('Prompt edits') },
        { name: 'Answers', data: Rollup.series('Prompt answers') },
        { name: 'Lucky Dipped', data: Rollup.series('Lucky dips') }
      ]
      @character_analytics = [
        { name: 'New', data: Rollup.series('Character creates') }
      ]
      @ticket_analytics = [
        { name: 'Used', data: Rollup.series('Ticket used') }
      ]
      @message_analytics = [
        { name: 'New', data: Rollup.series('Message creates') },
        { name: 'Edits', data: Rollup.series('Message edits') }
      ]
      @connect_code_analytics = [
        { name: 'New', data: Rollup.series('ConnectCode creates') },
        { name: 'Used', data: Rollup.series('ConnectCode consumes') }
      ]
    end
  end
end
