# frozen_string_literal: true

module Admin
  class AdsController < ApplicationController
    include Pagy::Backend
    include ApplicationHelper

    before_action :require_admin
    before_action :set_ad, only: %i[show destroy approve]

    # GET /admin/ads or /admin/ads.json
    def index
      ads_scope = Ad.all
      ads_scope = ads_scope.pending if params[:pending] == 'true'
      ads_scope = ads_scope.approved if params[:approved] == 'true'
      ads_scope = ads_scope.unapproved if params[:unapproved] == 'true'
      @pagy, @ads = pagy(ads_scope, items: 5)
    end

    # GET /admin/ads/1 or /admin/ads/1.json
    def show; end

    # DELETE /admin/ads/1 or /admin/ads/1.json
    def destroy
      @ad.destroy

      respond_to do |format|
        format.html do
          redirect_back fallback_location: admin_ads_path(pending: true), status: :see_other,
                        notice: 'Ad was successfully destroyed.'
        end
        format.json { head :no_content }
      end
    end

    def approve
      @ad.approved_image.attach(@ad.image.blob)
      @ad.approved_url = @ad.url
      @ad.pending_approval = false

      @ad.save(validate: false)

      respond_to do |format|
        format.html do
          redirect_back fallback_location: admin_ads_path(pending: true), status: :see_other,
                        notice: 'Ad has been approved.'
        end
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_ad
      @ad = Ad.find(params[:id])
    end
  end
end
