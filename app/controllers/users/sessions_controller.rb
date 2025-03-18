# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    prepend_before_action :validate_recaptchas, only: [:create]

    before_action :configure_sign_in_params, only: [:create]
    # before_action :ensure_not_deleted, only: [:create]

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    # def create
    #   super
    # end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    protected

    def validate_recaptchas
      v3_verify = verify_recaptcha(action: 'signin',
                                   minimum_score: 0.7,
                                   secret_key: ENV.fetch('RECAPTCHA_SECRET_KEY', nil))
      v2_verify = verify_recaptcha(secret_key: ENV.fetch('RECAPTCHA_SECRET_KEY_V2', nil))
      return if v3_verify || v2_verify

      self.resource = resource_class.new sign_in_params
      respond_with_navigational(resource) { render :new }
    end

    # If you have extra params to permit, append them to the sanitizer.
    def configure_sign_in_params
      devise_parameter_sanitizer.permit(:sign_in, keys: %i[username password])
    end
  end
end
