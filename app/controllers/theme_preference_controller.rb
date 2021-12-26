# frozen_string_literal: true

class ThemePreferenceController < ApplicationController
  def update
    cookies[:theme] = Rails.application.config.themes.include?(theme_params) ? theme_params : nil
    respond_to do |format|
      format.html do
        redirect_back fallback_location: root_path, status: cookies[:theme].nil? ? :bad_request : :see_other
      end
    end
  end

  # Only allow a list of trusted parameters through.
  def theme_params
    params.require(:theme)
  end
end
