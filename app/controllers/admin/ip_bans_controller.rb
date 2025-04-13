# frozen_string_literal: true

module Admin
  class IpBansController < ApplicationController
    include Pagy::Backend
    include ApplicationHelper

    before_action :require_admin
    before_action :set_ip_ban, only: %i[show edit update destroy]

    # GET /ip_bans or /ip_bans.json
    def index
      @pagy, @ip_bans = pagy(IpBan.all)
    end

    # GET /ip_bans/1 or /ip_bans/1.json
    def show; end

    # GET /ip_bans/new
    def new
      @ip_ban = IpBan.new
    end

    # GET /ip_bans/1/edit
    def edit; end

    # POST /ip_bans or /ip_bans.json
    def create
      params[:expires_on] = helpers.system_time_from_form(params[:expires_on]) if params[:expires_on].present?
      @ip_ban = IpBan.new(ip_ban_params)

      respond_to do |format|
        if @ip_ban.save
          format.html { redirect_to [:admin, @ip_ban], notice: 'IP Ban was successfully created.' }
          format.json { render :show, status: :created, location: [:admin, @ip_ban] }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @ip_ban.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /ip_bans/1 or /ip_bans/1.json
    def update
      params[:expires_on] = helpers.system_time_from_form(params[:expires_on]) if params[:expires_on].present?
      respond_to do |format|
        if @ip_ban.update(ip_ban_params)
          format.html { redirect_to [:admin, @ip_ban], notice: 'IP Ban was successfully updated.' }
          format.json { render :show, status: :ok, location: [:admin, @ip_ban] }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @ip_ban.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /ip_bans/1 or /ip_bans/1.json
    def destroy
      @ip_ban.destroy

      respond_to do |format|
        format.html { redirect_to ip_bans_path, status: :see_other, notice: 'IP Ban was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_ip_ban
      @ip_ban = IpBan.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ip_ban_params
      params.expect(ip_ban: %i[addr title context expires_on])
    end
  end
end
