# frozen_string_literal: true

class Theme < ApplicationRecord
  belongs_to :user
  has_many :users, dependent: :nullify

  validates :title, presence: true, length: { maximum: 64 }

  scope :available, ->(user) { where(user: user).or(where(system: true)).or(where(public: true)).order('system DESC') }

  after_update_commit :broadcast_changes

  def broadcast_changes
    users.each do |user_select|
      broadcast_update_to("user_#{user_select.id}_theme", target: 'theme',
                                                          partial: 'themes/stylesheet')
    end
  end
end
