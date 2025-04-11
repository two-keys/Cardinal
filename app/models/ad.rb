# frozen_string_literal: true

class Ad < ApplicationRecord
  VARIANT_SIZES = {
    footer: { w: 600, h: 100 },
    sidebar: { w: 300, h: 200 },
    sticky: { w: 300, h: 100 }
  }.freeze

  TIERS = {
    one: { footer: 1, sidebar: 0, sticky: 0 },
    two: { footer: 1, sidebar: 1, sticky: 0 },
    three: { footer: 1, sidebar: 1, sticky: 1 },
    unlimited: { footer: Float::INFINITY, sidebar: Float::INFINITY, sticky: Float::INFINITY }
  }.freeze

  MAX_FILESIZE = 2.megabytes

  enum :variant, { footer: 0, sidebar: 1, sticky: 2 }

  scope :approved, -> { joins(:approved_image_attachment).includes(:approved_image_attachment) }
  scope :pending, -> { where(pending_approval: true) }
  scope :unapproved, -> { where.missing(:approved_image_attachment) }

  validates_with AdCreationValidator, on: :create
  validates :url, url: true, if: -> { url.present? }
  validate :check_filesize, on: :update
  before_save :require_approval, if: -> { url_changed? || attachment_changes.keys.include?('image') }

  belongs_to :user

  has_one_attached :image do |image|
    image.variant :show, loader: { n: -1 },
                         resize_to_fit: [300, 300],
                         preprocessed: true
    image.variant :footer, loader: { n: -1 },
                           resize_to_limit: [VARIANT_SIZES[:footer][:w], VARIANT_SIZES[:footer][:h]],
                           preprocessed: true
    image.variant :sidebar, loader: { n: -1 },
                            resize_to_limit: [VARIANT_SIZES[:sidebar][:w], VARIANT_SIZES[:sidebar][:h]],
                            preprocessed: true
    image.variant :sticky, loader: { n: -1 },
                           resize_to_limit: [VARIANT_SIZES[:sticky][:w], VARIANT_SIZES[:sticky][:h]],
                           preprocessed: true
  end

  has_one_attached :approved_image do |image|
    image.variant :show, loader: { n: -1 },
                         resize_to_fit: [300, 300],
                         preprocessed: true
    image.variant :footer, loader: { n: -1 },
                           resize_to_limit: [VARIANT_SIZES[:footer][:w], VARIANT_SIZES[:footer][:h]],
                           preprocessed: true
    image.variant :sidebar, loader: { n: -1 },
                            resize_to_limit: [VARIANT_SIZES[:sidebar][:w], VARIANT_SIZES[:sidebar][:h]],
                            preprocessed: true
    image.variant :sticky, loader: { n: -1 },
                           resize_to_limit: [VARIANT_SIZES[:sticky][:w], VARIANT_SIZES[:sticky][:h]],
                           preprocessed: true
  end

  def self.ads_for(variant, count, view: false)
    valid_users = Rails.cache.fetch('valid_ad_users', expires_in: 30.seconds) do
      valid_users = []
      ad_entitlements = Entitlement.where(flag: 'ad-tier')
      ad_entitlements.each do |entitlement|
        entitlement.user_entitlements.where(expires_on: DateTime.now...)
                   .or(entitlement.user_entitlements.where(expires_on: nil))
                   .find_each do |user_entitlement|
          valid_users << user_entitlement.user_id
        end
      end
      valid_users = valid_users.uniq
      valid_users
    end

    ads = Ad.approved.where(user_id: valid_users,
                            variant: variant).order('RANDOM()').limit(count)
    return unless view

    ads.each(&:create_impression)
  end

  def require_approval
    self.pending_approval = true
  end

  def check_filesize
    errors.add(:image, 'must be provided') unless image.attached?
    return if image.blob.byte_size <= Ad::MAX_FILESIZE

    errors.add(:image,
               "must not exceed #{Ad::MAX_FILESIZE.to_filesize}")
  end

  def create_click
    ahoy = Ahoy.instance
    ahoy.track 'Ad Clicked', { user_id: Current.user&.id, owner_id: user_id, ad_id: id }
    increment!(:clicks) # rubocop:disable Rails/SkipsModelValidations
  end

  def create_impression
    ahoy = Ahoy.instance
    ahoy.track 'Ad Viewed', { user_id: Current.user&.id, owner_id: user_id, ad_id: id }
    increment!(:impressions) # rubocop:disable Rails/SkipsModelValidations
  end
end
