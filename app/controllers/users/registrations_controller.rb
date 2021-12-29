# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include ApplicationHelper

  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  def edit
    if is_admin?
      redirect_to edit_admin_user_path(current_user)
    else
      render :edit
    end
  end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  def destroy
    @user.delete_at = Time.now + 30.days
    @user.save
    sign_out_and_redirect(@user)
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email, :password, :password_confirmation])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :current_password])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    root_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    root_path
  end
end
