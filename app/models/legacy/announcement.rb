# frozen_string_literal: true

module Legacy
  class Announcement < Legacy::ApplicationRecord
    self.table_name = 'announcements'

    belongs_to :user, foreign_key: 'last_author', class_name: 'Legacy::User' # rubocop:disable Rails/InverseOf
  end
end
