# frozen_string_literal: true

module ReportsHelper
  def valid_rules
    rule_titles = CardinalSettings::Use.get_page('rules')['titles']

    rule_dict = {}
    rule_titles.each_with_index do |title, index|
      rule_dict["#{index + 1}. #{title}"] = index + 1
    end

    rule_dict
  end
end
