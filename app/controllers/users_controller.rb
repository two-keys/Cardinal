# frozen_string_literal: true

class UsersController < ApplicationController
  include ApplicationHelper

  # PUT /user
  # A separate endpoint for updating properties on the user
  # that do not need a password confirmation.
  def update
    respond_to do |format|
      if current_user.update(user_params)
        format.html { redirect_to edit_user_registration_path, notice: 'Settings have been updated' }
        format.json { render json: { status: 'ok' }, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def user_params
    params.expect(user: %i[push_announcements time_zone])
  end
end
