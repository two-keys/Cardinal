# frozen_string_literal: true

module Legacy
  class Prompt < Legacy::ApplicationRecord
    self.table_name = 'prompts'

    belongs_to :user, foreign_key: 'owner_id', class_name: 'Legacy::User' # rubocop:disable Rails/InverseOf
    belongs_to :character, class_name: 'Legacy::Character', optional: true
    has_many :chats, class_name: 'Legacy::Chat' # rubocop:disable Rails/HasManyOrHasOneDependent
  end
end
