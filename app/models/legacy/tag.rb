# frozen_string_literal: true

module Legacy
  class Tag < Legacy::ApplicationRecord
    self.table_name = 'tags'
    self.inheritance_column = 'inheritance_type'

    belongs_to :synonym, class_name: 'Legacy::Tag'
    belongs_to :parent, class_name: 'Legacy::Tag'

    has_many :synonyms, foreign_key: 'synonym_id', class_name: 'Legacy::Tag' # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
    has_many :children, foreign_key: 'parent_id', class_name: 'Legacy::Tag' # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
  end
end
