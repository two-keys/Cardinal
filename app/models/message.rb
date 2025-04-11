# frozen_string_literal: true

class Message < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include PgSearch::Model
  include Markdownable
  include Reportable
  include Alertable
  include Auditable
  MAX_CONTENT_LENGTH = 65_536

  belongs_to :chat
  belongs_to :user, optional: true

  validates_with MessageContentValidator
  validates :icon, presence: true, length: { maximum: 4000 }
  validates :color, format: { with: /\A#(?:[A-F0-9]{3}){1,2}\z/i }
  validate :authorization, on: :create
  validate :authorization, on: :update
  validate :visibility_change, on: :update
  before_validation :set_icon, on: :create

  scope :display, lambda { |viewing_user|
    return order('created_at DESC') if viewing_user&.admin?

    if viewing_user
      query = where('visibility != ? OR user_id = ?', Message.visibilities[:hidden], Current.user.id)
      return query.order('messages.created_at DESC') if viewing_user.shadowbanned?

      return query.includes(:user)
                  .where(user: { shadowbanned: false })
                  .or(query.where(user_id: nil))
                  .order('messages.created_at DESC')

    end

    where.not(visibility: 'hidden').order('created_at DESC')
  }

  before_create :override_visibility
  after_create :update_timestamp
  after_create_commit :update_chat
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_save_commit :search_reindex

  enum :visibility, { ic: 0, ooc: 1, hidden: 2 }, validate: { allow_nil: true }

  attribute :silent, :boolean, default: false

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
    chat.message_sent(self) unless Current.transfer
  end

  def broadcast_create # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if Current.transfer

    active_chat_users = chat.active_chat_users
    if user&.shadowbanned
      active_chat_users = active_chat_users.where(shadowbanned: true).or(active_chat_users.where(admin: true))
    end

    active_chat_users.each do |active_user|
      if chat.messages.count > 20
        if hidden?
          if active_user.admin? || active_user.id == user_id
            broadcast_remove_to("user_#{active_user.id}_chat_#{chat.id}", target: "message_#{chat.messages[-21].id}")
          end
        else
          broadcast_remove_to("user_#{active_user.id}_chat_#{chat.id}", target: "message_#{chat.messages[-21].id}")
        end
      end
      if hidden?
        if active_user.admin? || active_user.id == user_id
          broadcast_append_later_to("user_#{active_user.id}_chat_#{chat.id}",
                                    target: 'messages_container',
                                    partial: 'messages/message_frame', locals: { locals: { message: self } })
        end
      else
        broadcast_append_later_to("user_#{active_user.id}_chat_#{chat.id}",
                                  target: 'messages_container',
                                  partial: 'messages/message_frame', locals: { locals: { message: self } })
      end
    end
  end

  def broadcast_update
    return if Current.transfer

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
    order(id: :DESC).find_each(&:update_pg_search_document)
  end

  # def self.rebuild_pg_search_documents
  #   connection.execute <<~SQL.squish
  #    INSERT INTO pg_search_documents (searchable_type, searchable_id, content, created_at, updated_at)
  #      SELECT 'Movie' AS searchable_type,
  #             messages.id AS searchable_id,
  #             CONCAT_WS(' ', messages.content, chats.id, users.id) AS content,
  #             now() AS created_at,
  #             now() AS updated_at
  #      FROM messages
  #      LEFT JOIN users
  #        ON users.id = messages.user_id
  #      LEFT JOIN chats
  #        ON chats.id = messages.chat_id
  #   SQL
  # end

  def self.search(text)
    results = PgSearch.multisearch(text).where(searchable_type: 'Message').map(&:searchable_id)
    where(id: results)
  end

  def set_icon
    return unless icon.nil?

    self.icon = if user_id.nil?
                  CardinalSettings::Icons.system_icon
                else
                  chat_user = user.chat_users.find_by(chat_id:)
                  chat_user ? chat_user.icon : CardinalSettings::Icons.system_icon
                end
  end

  private

  def override_visibility
    self.visibility = 'ooc' if content.start_with?('((')
  end

  def search_reindex
    update_pg_search_document
  end

  def visibility_change
    return if user_id.nil?
    return if Current.user&.admin?
    return unless visibility == 'hidden' && visibility_was != 'hidden'

    errors.add(:status, 'cannot be changed to hidden from ic/ooc')
  end

  def authorization
    return if user_id.nil?
    return unless chat.users.include?(user)
    return unless user_id_changed? || (chat_id_changed? && persisted?)

    errors.add('You are not authorized to do that.')
  end
end
