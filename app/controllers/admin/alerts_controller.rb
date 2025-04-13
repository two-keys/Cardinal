# frozen_string_literal: true

module Admin
  class AlertsController < ApplicationController
    include Pagy::Backend
    include ApplicationHelper

    before_action :require_admin
    before_action :set_alert, only: %i[show edit update destroy]

    # GET /alerts or /alerts.json
    def index
      @pagy, @alerts = pagy(Alert.all)
    end

    # GET /alerts/1 or /alerts/1.json
    def show; end

    # GET /alerts/new
    def new
      @alert = Alert.new
    end

    # GET /alerts/1/edit
    def edit; end

    # POST /alerts or /alerts.json
    def create
      @alert = Alert.new(alert_params)

      respond_to do |format|
        if @alert.save
          format.html { redirect_to [:admin, @alert], notice: 'Alert was successfully created.' }
          format.json { render :show, status: :created, location: [:admin, @alert] }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @alert.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /alerts/1 or /alerts/1.json
    def update
      respond_to do |format|
        if @alert.update(alert_params)
          format.html { redirect_to [:admin, @alert], notice: 'Alert was successfully updated.' }
          format.json { render :show, status: :ok, location: [:admin, @alert] }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @alert.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /alerts/1 or /alerts/1.json
    def destroy
      @alert.destroy

      respond_to do |format|
        format.html { redirect_to alerts_path, status: :see_other, notice: 'Alert was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_alert
      @alert = Alert.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def alert_params
      params.expect(alert: %i[title find regex replacement])
    end
  end
end
