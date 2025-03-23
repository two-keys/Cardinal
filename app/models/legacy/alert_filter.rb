# frozen_string_literal: true

module Legacy
  class AlertFilter < Legacy::ApplicationRecord
    self.table_name = 'alert_filters'
    self.inheritance_column = 'inheritance_type'
  end
end
