# frozen_string_literal: true

class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :reportee, class_name: 'User'
  belongs_to :handled_by, class_name: 'User', optional: true
  belongs_to :reportable, polymorphic: true

  before_validation :sanitize_rules
  validate :validate_rules
  validate :validate_users
  validate :validate_reportable

  after_create :send_discord_message
  after_update :send_resolved_discord_message, if: proc { |report| report.handled? }

  def send_discord_message
    ApplicationController.helpers.send_discord_report(self)
  end

  def send_resolved_discord_message
    ApplicationController.helpers.send_discord_resolved_report(self)
  end

  private

  def sanitize_rules
    self.rules = rules.uniq
    self.rules = rules.select(&:positive?)
  end

  def validate_rules
    errors.add(:rules, 'must be an array.') unless rules.is_a?(Array)
    errors.add(:rules, 'must not be empty.') if rules.empty?

    @rule_count = CardinalSettings::Use.get_page('rules')['entries'].count
    rules.each do |rule|
      errors.add(:rules, "#{rule} is not a valid rule.") unless rule.between?(1, @rule_count)
    end
  end

  def validate_users
    errors.add(:reporter, 'cannot be the same as the reportee.') if reporter == reportee
  end

  def validate_reportable
    return unless handled == false && Report.exists?(reporter: reporter, reportable: reportable, handled: false)

    errors.add(:reportable, 'has already been reported by this reporter.')
  end
end
