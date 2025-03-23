# frozen_string_literal: true

module Legacy
  class User < Legacy::ApplicationRecord
    self.table_name = 'users'

    has_many :prompts, foreign_key: 'owner_id', class_name: 'Legacy::Prompt' # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
    has_many :characters, foreign_key: 'owner_id', class_name: 'Legacy::Character' # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
    has_many :chat_infos, class_name: 'Legacy::ChatInfo' # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :messages, foreign_key: 'message_sender', class_name: 'Legacy::Message' # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
    has_many :announcements, foreign_key: 'last_author', class_name: 'Legacy::Announcement' # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf

    def chats
      Legacy::Chat.chats_for(self)
    end
  end
end
