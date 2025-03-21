# frozen_string_literal: true

class UserTheme < ApplicationRecord
  belongs_to :user
  belongs_to :theme

  attribute :priority, default: :generate_priority

  default_scope { order(priority: :desc) }

  def generate_priority
    user_themes = UserTheme.where(user_id: user_id)

    if user_themes.count.positive?
      UserTheme.where(user_id: user.id).maximum(:priority) + 1
    else
      0
    end
  end
end
