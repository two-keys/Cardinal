# frozen_string_literal: true

module Debug
  class DebugPanelController < ApplicationController
    include ApplicationHelper

    before_action :require_admin_or_debug

    def index; end
  end
end
