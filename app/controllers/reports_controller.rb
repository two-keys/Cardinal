# frozen_string_literal: true

class ReportsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :set_report, only: %i[show]
  before_action :authenticate_user!
  before_action :sanitize_input_params, only: %i[create]

  after_action :track_create, only: :create

  authorize_resource

  def index
    @pagy, @reports = pagy(Report.where(reporter: current_user,
                                        handled: params[:handled] == 'true').order(created_at: :desc))
  end

  # GET /reports/1 or /reports/1.json
  def show; end

  # GET /reports/new
  def new
    @report = Report.new(context: nil)

    if params[:reportable_id].nil? || params[:reportable_type].nil?
      redirect_to root_path, alert: 'Invalid reportable type or ID'
      return
    end

    @report.reportable_id = params[:reportable_id] if params[:reportable_id].present?
    @report.reportable_type = params[:reportable_type] if params[:reportable_type].present?
    @report.reporter = current_user
    @report.reportee = @report.reportable.user

    redirect_to root_path, alert: 'Invalid reportable type or ID' if @report.reportee.nil?

    redirect_to root_path, alert: 'You do not have permission to report this item' if cannot? :read, @report.reportable

    authorize! :create, @report
  end

  # POST /reports or /reports.json
  def create
    @report = Report.new(report_params)
    @report.reporter = current_user
    @report.reportee = @report.reportable.user
    authorize! :create, @report
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_report
    @report = Report.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  # Reports are polymorphic covering Prompts, Messages, and Characters
  def report_params
    params.expect(report: [:reportable_id, :reportable_type, :context, { rules: [] }])
  end

  def sanitize_input_params
    # Convert strings to integers and remove any non-integer values
    params[:report][:rules] = params[:report][:rules].map(&:to_i).select(&:positive?) if params[:report][:rules]&.any?
  end

  def track_create
    ahoy.track 'Report Created', { reporter_id: @report.reporter.id, reportee_id: @report.reportee.id }
  end
end
