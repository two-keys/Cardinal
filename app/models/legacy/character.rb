# frozen_string_literal: true

module Legacy
  class Character < Legacy::ApplicationRecord
    self.table_name = 'characters'

    belongs_to :user, foreign_key: 'owner_id', class_name: 'Legacy::User' # rubocop:disable Rails/InverseOf
    has_many :prompts, class_name: 'Legacy::Prompt' # rubocop:disable Rails/HasManyOrHasOneDependent
  end
end
