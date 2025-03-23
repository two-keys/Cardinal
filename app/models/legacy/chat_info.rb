# frozen_string_literal: true

module Legacy
  class ChatInfo < Legacy::ApplicationRecord
    self.table_name = 'chat_info'

    belongs_to :user, class_name: 'Legacy::Prompt'
    belongs_to :chat, class_name: 'Legacy::Chat'
  end
end
