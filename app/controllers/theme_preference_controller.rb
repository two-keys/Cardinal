class ThemePreferenceController < ApplicationController
  def update
    if Rails.application.config.themes.include? theme_params
      cookies.permanent[:theme] = theme_params
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path }
      end
    else
      cookies[:theme] = nil
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, status: :bad_request }
      end
    end
  end

  # Only allow a list of trusted parameters through.
  def theme_params
    params.require(:theme)
  end
end
