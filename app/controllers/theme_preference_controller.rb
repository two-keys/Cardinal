class ThemePreferenceController < ApplicationController
  def update
    if Rails.application.config.themes.include? theme_params
      cookies[:theme] = theme_params
    else
      cookies[:theme] = nil
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
    end
  end

  # Only allow a list of trusted parameters through.
  def theme_params
    params.require(:theme)
  end
end
