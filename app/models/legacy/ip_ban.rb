# frozen_string_literal: true

module Legacy
  class IpBan < Legacy::ApplicationRecord
    self.table_name = 'ip_bans'
  end
end
