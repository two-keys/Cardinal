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

  def admin?
    user_signed_in? && current_user.admin?
  end

  # User can update given model
  # Some models shouldn't be editable even if a user is an admin (See, messages)
  def can_edit?(model)
    model.user_id == current_user.id || (model.moderatable && admin?)
  end
end
