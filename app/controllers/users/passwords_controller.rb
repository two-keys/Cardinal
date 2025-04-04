# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    invisible_captcha only: %i[create], honeypot: :username
  end
end
