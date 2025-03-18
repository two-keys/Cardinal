# frozen_string_literal: true

module AdminPanelHelper
  def admin_scoped?(model)
    return true if %i[user entitlement].include?(model)

    false
  end

  def default_edit?(model)
    return true if %i[user].include?(model)

    false
  end
end
