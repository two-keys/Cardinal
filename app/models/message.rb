# frozen_string_literal: true

class Message < ApplicationRecord
  include PgSearch::Model
  include Markdownable
  include Reportable
  include Alertable
  include Auditable
  MAX_CONTENT_LENGTH = 65_536

  belongs_to :chat
  belongs_to :user, optional: true

  validates_with MessageContentValidator
  validates :icon, presence: true, length: { maximum: 70 }
  validate :authorization, on: :create
  validate :authorization, on: :update

  before_validation :set_icon, on: :create

  scope :display, -> { order('created_at DESC') }

  after_create :update_timestamp
  after_create_commit :update_chat
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_save_commit :search_reindex

  multisearchable(
    against: [:content],
    additional_attributes: ->(message) { { chat_id: message.chat_id, user_id: message.user_id } }
  )

  def alertable_fields
    %i[content]
  end

  def update_timestamp
    return if chat.frozen?

    Chat.record_timestamps = false
    chat.updated_at = Time.zone.now
    Chat.record_timestamps = true
    chat.save!
  end

  def update_chat
    chat.message_sent
  end

  def broadcast_create
    chat.active_chat_users.each do |active_user|
      if chat.messages.count > 20
        broadcast_remove_to("user_#{active_user.id}_chat_#{chat.id}", target: "message_#{chat.messages[-21].id}")
      end
      broadcast_append_later_to("user_#{active_user.id}_chat_#{chat.id}",
                                target: 'messages_container',
                                partial: 'messages/message_frame', locals: { locals: { message: self } })
    end
  end

  def broadcast_update
    chat.active_chat_users.each do |active_user|
      broadcast_replace_later_to("user_#{active_user.id}_chat_#{chat.id}",
                                 target: "message_#{id}",
                                 partial: 'messages/message_frame', locals: { locals: { message: self } })
    end
  end

  def markdown
    markdown_concern(content)
  end

  def type
    if user_id.nil?
      'system'
    else
      'user'
    end
  end

  def surrounding_messages(amount = 5)
    result = chat.messages.where(created_at: ...created_at).last(amount) +
             [self] +
             chat.messages.where('created_at > ?', created_at).first(amount)
    result.reverse
  end

  def self.rebuild_pg_search_documents
    find_each(&:update_pg_search_document)
  end

  def self.search(text)
    results = PgSearch.multisearch(text).where(searchable_type: 'Message').map(&:searchable_id)
    where(id: results)
  end

  private

  def search_reindex
    update_pg_search_document
  end

  def set_icon
    self.icon = if user_id.nil?
                  CardinalSettings::Icons.system_icon
                else
                  chat_user = user.chat_users.find_by(chat_id:)
                  chat_user ? chat_user.icon : CardinalSettings::Icons.system_icon
                end
  end

  def authorization
    return if user_id.nil?
    return unless chat.users.include?(user)
    return unless user_id_changed? || (chat_id_changed? && persisted?)

    errors.add('You are not authorized to do that.')
  end
end
