# frozen_string_literal: true

module Admin
  class AdminPanelController < ApplicationController
    include ApplicationHelper

    before_action :require_admin

    def index; end
  end
end
