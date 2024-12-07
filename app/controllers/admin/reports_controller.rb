# frozen_string_literal: true

module Admin
  class ReportsController < ApplicationController
    include Pagy::Backend
    include ApplicationHelper

    before_action :require_admin
    before_action :set_report, only: %i[show edit update destroy]

    # GET /admin/reports or /admin/reports.json
    def index
      @pagy, @reports = pagy(Report.where(handled: params[:handled] == 'true').order(created_at: :desc))
    end

    # GET /admin/reports/1 or /admin/reports/1.json
    def show; end

    # GET /admin/reports/new
    def new
      @report = Report.new
    end

    # GET /admin/reports/1/edit
    def edit; end

    # POST /admin/reports or /admin/reports.json
    def create
      @report = Report.new(report_params)

      respond_to do |format|
        if @report.save
          format.html { redirect_to @report, notice: 'Report was successfully created.' }
          format.json { render :show, status: :created, location: @report }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @report.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /admin/reports/1 or /admin/reports/1.json
    def update
      respond_to do |format|
        if @report.update(report_params)
          format.html { redirect_to @report, notice: 'Report was successfully updated.' }
          format.json { render :show, status: :ok, location: @report }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @report.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /admin/reports/1 or /admin/reports/1.json
    def destroy
      @report.handled = true
      @report.handled_by = current_user
      @report.save

      respond_to do |format|
        format.html { redirect_to admin_reports_path, status: :see_other, notice: 'Report was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_report
      @report = Report.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def report_params
      params.fetch(:report, {})
    end
  end
end
