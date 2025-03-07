# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    include ActiveSnapshot

    after_create_commit :new_create_snapshot!
    after_update_commit :new_update_snapshot!
    before_destroy :new_destroy_snapshot!

    after_validation :allow_snapshot, on: %i[update]

    attr_accessor :children_hash
    attr_accessor :will_snapshot

    def self.get_versions(item_id)
      ActiveSnapshot::Snapshot.where(item_type: name, item_id: item_id).order('created_at DESC')
    end

    # Workaround to prevent restoration of snapshots
    # from generating new snapshots
    def allow_snapshot
      self.will_snapshot = true
    end

    def new_destroy_snapshot!
      create_snapshot!(
        user: Current.user,
        metadata: {
          ip: Current.remote_ip,
          user_agent: Current.user_agent,
          controller: Current.controller_name,
          action: Current.action_name,
          event: 'create'
        }
      )
    end

    def new_create_snapshot!
      create_snapshot!(
        user: Current.user,
        metadata: {
          ip: Current.remote_ip,
          user_agent: Current.user_agent,
          controller: Current.controller_name,
          action: Current.action_name,
          event: 'create'
        }
      )
    end

    def new_update_snapshot!
      unless will_snapshot
        self.will_snapshot = false
        return
      end
      create_snapshot!(
        user: Current.user,
        metadata: {
          ip: Current.remote_ip,
          user_agent: Current.user_agent,
          controller: Current.controller_name,
          action: Current.action_name,
          event: 'update'
        }
      )
    end
  end
end
