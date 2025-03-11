# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    include ApplicationHelper

    before_action :configure_sign_up_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]

    after_action :track_create, only: :create
    after_action :track_destroy, only: :destroy

    authorize_resource except: %i[new create], class: User

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
      render :edit
    end

    # PUT /resource
    # def update
    #   super
    # end

    # DELETE /resource
    def destroy
      @user.delete_at = 30.days.from_now
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
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[username email password password_confirmation])
    end

    # If you have extra params to permit, append them to the sanitizer.
    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update,
                                        keys: %i[email password password_confirmation current_password
                                                 push_announcements])
    end

    # The path used after sign up.
    def after_sign_up_path_for(_resource)
      root_path
    end

    # The path used after sign up for inactive accounts.
    def after_inactive_sign_up_path_for(_resource)
      root_path
    end

    def track_create
      ahoy.track 'User Created'
    end

    def track_destroy
      ahoy.track 'User Destroyed'
    end
  end
end
