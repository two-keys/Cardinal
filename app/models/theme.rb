# frozen_string_literal: true

class Theme < ApplicationRecord
  include Auditable
  include Entitlementable

  belongs_to :user
  has_many :users, dependent: :nullify
  has_many :user_themes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 64 }

  scope :entitled, lambda { |user|
    where(id: user.entitlements.where(object_type: 'Theme').pluck(:object_id)).order('system DESC, created_at DESC')
  }
  scope :publicized, -> { where(system: true).or(where(public: true)).order('system DESC, created_at DESC') }
  scope :available, ->(user) { entitled(user).or(publicized).order('system DESC, created_at DESC') }

  default_scope { includes(:user) }

  after_update_commit :broadcast_changes

  def broadcast_changes
    users.each do |user_select|
      broadcast_update_to("user_#{user_select.id}_theme", target: 'theme',
                                                          partial: 'themes/stylesheet')
    end
  end
end
