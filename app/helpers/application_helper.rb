# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def require_admin
    return if user_signed_in? && current_user.admin?

    respond_to do |format|
      format.html { redirect_to root_url, notice: 'You are not authorized to perform this action.' }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def is_admin?
    user_signed_in? && current_user.admin?
  end
end
