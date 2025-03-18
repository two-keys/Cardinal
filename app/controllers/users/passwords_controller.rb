# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    # TODO: Fix this. it's broken, we're not using it right now.
    prepend_before_action :validate_recaptchas, only: [:create]

    private

    def validate_recaptchas
      v3_verify = verify_recaptcha(action: 'password/reset',
                                   minimum_score: 0.7,
                                   secret_key: ENV.fetch('RECAPTCHA_SECRET_KEY', nil))
      v2_verify = verify_recaptcha(secret_key: ENV.fetch('RECAPTCHA_SECRET_KEY_V2', nil))
      return if v3_verify || v2_verify

      self.resource = resource_class.new resource_params
      respond_with_navigational(resource) { render :new }
    end
  end
end
