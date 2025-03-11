# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  authorize_resource

  def create
    subscription = PushSubscription.find_by(push_subscription_params)

    if subscription
      subscription.touch # rubocop:disable Rails/SkipsModelValidations
    else
      PushSubscription.create! push_subscription_params.merge(user_agent: request.user_agent, user: current_user)
    end

    head :ok
  end

  def destroy
    subscription = PushSubscription.find(params[:id])
    subscription.destroy

    respond_to do |format|
      format.html { redirect_to edit_user_registration_url, notice: 'Subscription was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def push_subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key)
  end
end
