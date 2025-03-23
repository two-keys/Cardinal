# frozen_string_literal: true

module Legacy
  class Chat < Legacy::ApplicationRecord
    self.table_name = 'chats'

    belongs_to :prompt, class_name: 'Legacy::Prompt'

    has_many :chat_infos, class_name: 'Legacy::ChatInfo' # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :users, through: :chat_infos, class_name: 'Legacy::User'
    has_many :messages, class_name: 'Legacy::Message' # rubocop:disable Rails/HasManyOrHasOneDependent

    def self.chats_for(legacy_user)
      Legacy::Chat.where('participants @> ?', "{#{legacy_user.id}}")
    end
  end
end
