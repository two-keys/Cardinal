# frozen_string_literal: true

# Accessing these in in model callbacks requires this
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :remote_ip
  attribute :user_agent
  attribute :controller_name
  attribute :action_name
end
