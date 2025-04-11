# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Pagy::Backend
    include ApplicationHelper
    include AuditableController

    before_action :require_admin
    before_action :set_user, only: %i[show edit update destroy force_confirm generate_password_reset]

    # GET /admin/users or /admin/users.json
    def index # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      query = User.includes(:pseudonyms, :characters)
      params = request.query_parameters
      params = params.compact_blank if params
      params[:banned] = nil if params[:banned].present? && params[:banned] != '1'
      if params
        query = query.where(username: params[:username]) if params[:username].present?
        if params[:ip].present?
          query = query.where(last_sign_in_ip: params[:ip]).or(query.where(current_sign_in_ip: params[:ip]))
        end
        if params[:banned].present?
          query = if params[:banned] == '1'
                    query.where.not(unban_at: nil)
                  else
                    query.where(unban_at: nil)
                  end
        end
      end
      @pagy, @users = pagy(query, items: 5)
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show; end

    # GET /admin/users/new
    def new
      @user = User.new
    end

    # GET /admin/users/1/edit
    def edit # rubocop:disable Metrics/CyclomaticComplexity
      @pagy_ads, @ads = pagy(@user.ads, items: 5, page: params[:ads_page])
      @pagy_prompts, @prompts = pagy(@user.prompts.includes(:pseudonym), items: 5, page: params[:prompts_page])
      @pagy_sent_reports, @sent_reports = pagy(@user.sent_reports, items: 5, page: params[:made_reports_page])
      @pagy_received_reports, @received_reports = pagy(@user.received_reports, items: 5,
                                                                               page: params[:received_reports_page])
      @pagy_handled_reports, @handled_reports = pagy(@user.handled_reports, items: 5,
                                                                            page: params[:handled_reports_page])
      query = @user.entitlements.includes(:object, :user_entitlements).order(created_at: :desc)
      if params[:object_type].present?
        query = query.where(object_type: params[:object_type] == 'None' ? nil : params[:object_type])
      end
      query = query.where(object_id: params[:object_id]) if params[:object_id].present?
      query = query.where(flag: params[:flag]) if params[:flag].present?
      query = query.where(data: params[:data]) if params[:data].present?
      query = query.where(created_at: Date.parse(params[:date_from]).beginning_of_day..) if params[:date_from].present?
      query = query.where(created_at: ..Date.parse(params[:date_to]).end_of_day) if params[:date_to].present?
      @pagy_entitlements, @entitlements = pagy(query, items: 5,
                                                      page: params[:entitlements_page])
    end

    # POST /admin/users or /admin/users.json
    def create
      @user = User.new(user_params)

      @user.skip_confirmation_notification! unless ENV.fetch('MAIL_ENABLED', 0).to_i == 1

      respond_to do |format|
        if @user.save
          format.html { redirect_to edit_admin_user_path(@user), notice: 'User was successfully created.' }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      respond_to do |format|
        if @user.update(user_params)
          format.html { redirect_to edit_admin_user_path(@user), notice: 'User was successfully updated.' }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    def force_confirm
      respond_to do |format|
        if @user.confirm
          format.html { redirect_to edit_admin_user_path(@user), notice: 'User was successfully updated.' }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    def generate_password_reset
      @user.password_reset_url = Rails.application.routes.url_helpers.edit_user_password_url(reset_password_token: @user.send(:set_reset_password_token)) # rubocop:disable Layout/LineLength

      respond_to do |format|
        if @user.password_reset_url.blank?
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        else
          format.html do
            redirect_to edit_admin_user_path(@user), notice: 'Password Reset URL Generated. Please copy it.'
          end
          format.json { render :show, status: :ok, location: @user }
        end
      end
    end

    # DELETE /admin/users/1 or /admin/users/1.json
    def destroy
      @user.delete_at = 30.days.from_now
      @user.save

      respond_to do |format|
        format.html { redirect_to admin_users_path, notice: 'User was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def model_class
      'user'
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      Rails.logger.debug params
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :verified, :unban_at,
                                   :ban_reason, :delete_at)
    end
  end
end
