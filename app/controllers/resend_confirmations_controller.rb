# frozen_string_literal: true

class ResendConfirmationsController < ApplicationController
  include ApplicationHelper

  def resend
    current_user.send_reconfirmation_instructions
    respond_to do |format|
      format.html { redirect_to edit_user_registration_path, notice: 'Confirmation email sent.' }
    end
  end
end
