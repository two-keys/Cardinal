# frozen_string_literal: true

class AdsController < ApplicationController
  include Pagy::Backend
  before_action :set_ad, only: %i[show edit update destroy click]

  load_and_authorize_resource

  # GET /ads or /ads.json
  def index
    @ad_usage = current_user.ad_usage
    ads_scope = current_user.ads
    ads_scope = ads_scope.pending if params[:pending] == 'true'
    ads_scope = ads_scope.approved if params[:approved] == 'true'
    ads_scope = ads_scope.unapproved if params[:unapproved] == 'true'
    @pagy, @ads = pagy(ads_scope, items: 5)
  end

  # GET /ads/1 or /ads/1.json
  def show
    @interval = params[:interval] || '5m'
    now = DateTime.now

    @begin_date = params[:date_from].present? ? helpers.system_time_from_form(params[:date_from]) : (now - 1.day)
    @end_date = params[:date_to].present? ? helpers.system_time_from_form(params[:date_to]) : (now + 1.minute)

    @begin_date = @ad.created_at if @begin_date < @ad.created_at
    @end_date = now if @end_date > now

    @range = @begin_date...@end_date

    @intervals = %w[1s 30s 90s 1m 5m 15m hour day week month quarter year]

    Ahoy::Event.where_event('Ad Viewed', ad_id: @ad.id).rollup("Ad #{@ad.id} views", column: :time,
                                                                                     interval: @interval)
    Ahoy::Event.where_event('Ad Clicked', ad_id: @ad.id).rollup("Ad #{@ad.id} clicks", column: :time,
                                                                                       interval: @interval)
    @ad_analytics = [
      { name: 'Views', data: Rollup.where(time: @range).series("Ad #{@ad.id} views", interval: @interval) },
      { name: 'Clicks', data: Rollup.where(time: @range).series("Ad #{@ad.id} clicks", interval: @interval) }
    ]
  end

  # GET /ads/new
  def new
    @ad = Ad.new
    @ad_usage = current_user.ad_usage
  end

  # GET /ads/1/edit
  def edit; end

  # POST /ads or /ads.json
  def create
    @ad = Ad.new(ad_params)
    @ad.user = current_user
    @ad_usage = current_user.ad_usage

    respond_to do |format|
      if @ad.save
        format.html { redirect_to @ad, notice: 'Ad was successfully created.' }
        format.json { render :show, status: :created, location: @ad }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ad.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ads/1 or /ads/1.json
  def update
    respond_to do |format|
      if @ad.update(edit_ad_params)
        format.html { redirect_to @ad, notice: 'Ad was successfully updated.' }
        format.json { render :show, status: :ok, location: @ad }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ad.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ads/1 or /ads/1.json
  def destroy
    @ad.destroy!

    respond_to do |format|
      format.html { redirect_to ads_path, status: :see_other, notice: 'Ad was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def click
    @ad.create_click

    respond_to do |format|
      format.html { redirect_to @ad.approved_url || root_path, allow_other_host: true }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ad
    @ad = Ad.find(params[:id])
    @ad_usage = current_user.ad_usage
  end

  # Only allow a list of trusted parameters through.
  def ad_params
    params.require(:ad).permit(:image, :variant, :url)
  end

  def edit_ad_params
    params.require(:ad).permit(:image, :url)
  end
end
