# frozen_string_literal: true

module Debug
  class CrashController < ApplicationController
    include ApplicationHelper
    layout false, only: [:index]

    def index
      raise 'error'
    end
  end
end
