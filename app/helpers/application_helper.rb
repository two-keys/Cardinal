# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def require_admin
    return if admin?

    respond_to do |format|
      format.html { redirect_to root_url, notice: 'You are not authorized to perform this action.' }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def require_active_user
    return if !banned? && !deleted?

    respond_to do |format|
      format.html { redirect_to root_url, notice: 'You are not authorized to perform this action.' }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def admin?
    user_signed_in? && current_user.admin?
  end

  def banned?
    user_signed_in? && !current_user.unban_at.nil?
  end

  def deleted?
    user_signed_in? && !current_user.delete_at.nil?
  end
end
