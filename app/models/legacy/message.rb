# frozen_string_literal: true

module Legacy
  class Message < Legacy::ApplicationRecord
    self.table_name = 'messages'

    belongs_to :user, foreign_key: 'message_sender', class_name: 'Legacy::User' # rubocop:disable Rails/InverseOf
    belongs_to :chat, class_name: 'Legacy::Chat'
  end
end
