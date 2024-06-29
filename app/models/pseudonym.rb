# frozen_string_literal: true

class Pseudonym < ApplicationRecord
  include Ticketable
  MIN_CONTENT_LENGTH = 10

  belongs_to :user

  has_many :characters, dependent: :nullify
  has_many :chat_users, dependent: :nullify
  has_many :prompts, dependent: :nullify
  # has_many :object_tags, as: :object, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  enum status: {
    draft: 0,
    locked: 1,
    posted: 2
  }

  validates :status, inclusion: { in: Pseudonym.statuses }
  validate :can_spend, on: %i[create update]

  after_create :spend_ticket

  default_scope { order(updated_at: :desc) }

  private

  def spend_ticket
    Ticket.spend(self)
  end
end
