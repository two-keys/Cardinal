# frozen_string_literal: true

class User < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Auditable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  validates :username, presence: true, uniqueness: true
  validates :email, uniqueness: { allow_blank: true }

  has_many :pseudonyms, dependent: :destroy
  has_many :chat_users, dependent: :destroy
  has_many :chats, through: :chat_users
  has_many :mod_chats, dependent: :destroy
  has_many :prompts, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :filters, dependent: :destroy
  has_many :messages, dependent: :delete_all
  has_many :connect_codes, dependent: :destroy
  has_many :tickets, dependent: :delete_all
  has_many :sent_reports, class_name: 'Report', foreign_key: 'reporter_id', dependent: :delete_all,
                          inverse_of: 'reporter'
  has_many :received_reports, class_name: 'Report', foreign_key: 'reportee_id', dependent: :delete_all,
                              inverse_of: 'reportee'
  has_many :handled_reports, class_name: 'Report', foreign_key: 'handled_by_id', dependent: :delete_all,
                             inverse_of: 'handled_by'
  has_many :themes, dependent: :nullify
  has_many :push_subscriptions, dependent: :delete_all
  has_many :user_entitlements, dependent: :delete_all
  has_many :entitlements, through: :user_entitlements do
    def active(object: nil)
      value = where("coalesce(user_entitlements.expires_on, 'infinity') > ?", Time.zone.now)
      value = value.where(object: object) unless object.nil?
      value
    end
  end
  has_many :ads, dependent: :delete_all

  # TODO: Remove after migration
  belongs_to :theme, optional: true

  has_many :user_themes, dependent: :delete_all
  has_many :applied_themes, through: :user_themes, source: :theme, class_name: 'Theme', foreign_key: 'theme_id'

  after_create_commit :generate_pseudonym_entitlement

  delegate :can?, :cannot?, to: :ability

  has_snapshot_children do
    instance = self.class.includes(:pseudonyms, :characters).find(id)
    {
      pseudonyms: instance.pseudonyms,
      characters: instance.characters
    }
  end

  def ad_usage
    footer_ads = ads.where(variant: 'footer').count
    sidebar_ads = ads.where(variant: 'sidebar').count
    sticky_ads = ads.where(variant: 'sticky').count

    ad_entitlements = entitlements.where(flag: 'ad-tier').where.not(data: nil)

    usage = {
      footer: { used: footer_ads, entitled: 0 },
      sidebar: { used: sidebar_ads, entitled: 0 },
      sticky: { used: sticky_ads, entitled: 0 },
      used: footer_ads + sidebar_ads + sticky_ads,
      entitled: 0
    }

    ad_entitlements.each do |entitlement|
      usage[:footer][:entitled] += Ad::TIERS[entitlement.data.to_sym][:footer]
      usage[:entitled] += usage[:footer][:entitled]
      usage[:sidebar][:entitled] += Ad::TIERS[entitlement.data.to_sym][:sidebar]
      usage[:entitled] += usage[:sidebar][:entitled]
      usage[:sticky][:entitled] += Ad::TIERS[entitlement.data.to_sym][:sticky]
      usage[:entitled] += usage[:sticky][:entitled]
    end

    usage
  end

  def generate_pseudonym_entitlement
    return if Entitlement.where(flag: 'pseudonym', data: username).any?

    entitlements << Entitlement.create!(flag: 'pseudonym', data: username)
  end

  def after_database_authentication
    return unless unbannable?

    unban
  end

  def valid_subscription?
    entitlements.active.where(flag: 'subscription').any?
  end

  def active_for_authentication?
    super && !delete_at && unbannable?
  end

  def email_required?
    true unless legacy? && email.blank?
  end

  def debug?
    entitlements.active.where(flag: 'debug').any?
  end

  def unbannable?
    (unban_at.to_i < DateTime.now.to_i)
  end

  def unban
    self.unban_at = nil
    self.ban_reason = nil
    save
  end

  def password_reset_url=(url)
    Rails.cache.write("user_#{id}_reset_url", url, expires_in: 30.seconds)
  end

  def password_reset_url
    Rails.cache.read("user_#{id}_reset_url")
  end

  def inactive_message
    return unless delete_at || unban_at

    return 'This account is pending for deletion.' if delete_at

    "You are banned for the following: '#{ban_reason}', and your ban lasts until #{unban_at.to_fs(:long_ordinal)}"
  end

  def joined?(chat)
    chats.exists?(id: chat.id)
  end

  def notifications
    notifications = ChatUser.where(user: self, status: %i[unread unanswered ended])
    unread_count = notifications.where(status: :unread).count
    unanswered_count = notifications.where(status: :unanswered).count
    ended_count = notifications.where(status: :ended).count
    { unread: unread_count, unanswered: unanswered_count, ended: ended_count }
  end

  # cancancan hack to make it stop screaming because of Devise's weird and shitty controller names.
  def user
    self
  end

  def ability
    @ability ||= Ability.new(self)
  end
end
