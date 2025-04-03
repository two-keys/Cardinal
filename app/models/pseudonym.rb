# frozen_string_literal: true

class Pseudonym < ApplicationRecord
  include Ticketable
  include Entitlementable
  MIN_CONTENT_LENGTH = 10

  belongs_to :user

  has_many :characters, dependent: :nullify
  has_many :chat_users, dependent: :nullify
  has_many :prompts, dependent: :nullify
  # has_many :object_tags, as: :object, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  enum :status, {
    draft: 0,
    locked: 1,
    posted: 2
  }

  validates :status, inclusion: { in: Pseudonym.statuses }
  validate :can_spend, on: %i[create update], unless: -> { Current.user&.admin? && Current.user != user }
  validate :reserved?

  after_create :spend_ticket, unless: -> { Current.user&.admin? && Current.user != user }

  default_scope { order(updated_at: :desc) }

  private

  def spend_ticket
    Ticket.spend(self)
  end

  def reserved?
    reserved_pseudonyms = Entitlement.where.not(data: [nil, '']).where(flag: 'pseudonym').map(&:data)
    entitled_pseudonyms = user.entitlements.where.not(data: [nil, '']).where(flag: 'pseudonym').map(&:data)

    return false unless reserved_pseudonyms.include?(name) && entitled_pseudonyms.exclude?(name)

    errors.add :name, 'You are not entitled to this pseudonym'
  end

  def generate_entitlement
    entitlement = Entitlement.find_by(flag: 'pseudonym', data: name)
    if entitlement
      entitlement.object = self
      entitlement.save!
    else
      entitlement = Entitlement.create!(object: self, flag: 'pseudonym', data: name)
      user.entitlements << entitlement if user.entitlements.exclude?(entitlement)
    end
  end

  def entitlements_for(user)
    user.entitlements.where.not(data: [nil, '']).where(flag: 'pseudonym')
  end
end
