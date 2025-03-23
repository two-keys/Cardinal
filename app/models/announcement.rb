# frozen_string_literal: true

class Announcement < ApplicationRecord
  include Markdownable
  include Auditable

  after_create_commit :push_to_users

  validates :content, presence: true

  default_scope { order('created_at DESC') }

  def push_to_users
    return unless push

    users = User.where(push_announcements: true)

    PushSubscription.where(user: users).find_each do |subscription|
      subscription.push(title, 'Click to view Announcement', url: "/announcements/#{id}")
    end
  end

  def markdown
    markdown_concern(content)
  end
end
