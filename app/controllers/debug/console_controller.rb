# frozen_string_literal: true

module Debug
  class ConsoleController < ApplicationController
    include ApplicationHelper
    layout false, only: [:index]

    before_action :require_debug

    def index; end
  end
end
