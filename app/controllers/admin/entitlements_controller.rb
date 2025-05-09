# frozen_string_literal: true

module Admin
  class EntitlementsController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Pagy::Backend
    include ApplicationHelper

    before_action :require_admin
    before_action :set_entitlement, only: %i[show edit update destroy]

    # GET /admin/entitlements or /admin/entitlements.json
    def index # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      user = User.find_by(username: params[:username])
      query = Entitlement.includes(:object, :user_entitlements).order(created_at: :desc)
      query = user.entitlements.order(created_at: :desc) if user.present?
      if params[:object_type].present?
        query = query.where(object_type: params[:object_type] == 'None' ? nil : params[:object_type])
      end
      query = query.where(object_id: params[:object_id]) if params[:object_id].present?
      query = query.where(flag: params[:flag]) if params[:flag].present?
      query = query.where(data: params[:data]) if params[:data].present?
      query = query.where(created_at: Date.parse(params[:date_from]).beginning_of_day..) if params[:date_from].present?
      query = query.where(created_at: ..Date.parse(params[:date_to]).end_of_day) if params[:date_to].present?
      @pagy, @entitlements = pagy(query)
    end

    # GET /admin/entitlements/1 or /admin/entitlements/1.json
    def show; end

    # GET /admin/entitlements/new
    def new
      @entitlement = Entitlement.new
    end

    # GET /admin/entitlements/1/edit
    def edit; end

    # POST /admin/entitlements or /admin/entitlements.json
    def create
      @entitlement = Entitlement.new(entitlement_params.except(:username))

      respond_to do |format|
        if @entitlement.save
          format.html { redirect_to [:admin, @entitlement], notice: 'Entitlement was successfully created.' }
          format.json { render :show, status: :created, location: @entitlement }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @entitlement.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /admin/entitlements/1 or /admin/entitlements/1.json
    def update # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      case params[:commit]
      when 'Update Entitlement'
        respond_to do |format|
          if @entitlement.update(entitlement_params.except(:username))
            format.html { redirect_to [:admin, @entitlement], notice: 'Entitlement was successfully updated.' }
            format.json { render :show, status: :ok, location: @entitlement }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @entitlement.errors, status: :unprocessable_entity }
          end
        end
      when 'Add'
        user = User.find_by(username: entitlement_params[:username])
        if user.nil?
          respond_to do |format|
            format.html do
              redirect_to edit_admin_entitlement_path(@entitlement), notice: 'Username not found.'
            end
          end
        else
          user_entitlement = user.user_entitlements.find_by(entitlement: @entitlement) || UserEntitlement.new
          user_entitlement.entitlement = @entitlement
          user_entitlement.user = user
          if entitlement_params[:expires_on].present?
            user_entitlement.expires_on = helpers.system_time_from_form(entitlement_params[:expires_on])
          end
          user_entitlement.save!
          respond_to do |format|
            format.html do
              redirect_to edit_admin_entitlement_path(@entitlement), notice: 'Entitlement given to user.'
            end
          end
        end

      when 'Remove'
        user = User.find_by(username: entitlement_params[:username])
        if user.nil?
          format.html do
            redirect_to edit_admin_entitlement_path(@entitlement), notice: 'Username not found.'
          end
        else
          UserEntitlement.where(user: user, entitlement: @entitlement).destroy_all
          respond_to do |format|
            format.html do
              redirect_to edit_admin_entitlement_path(@entitlement), notice: 'Entitlement removed from user.'
            end
          end
        end
      end
    end

    # DELETE /admin/entitlements/1 or /admin/entitlements/1.json
    def destroy
      @entitlement.destroy

      respond_to do |format|
        format.html do
          redirect_to admin_entitlements_path, status: :see_other, notice: 'Entitlement was successfully destroyed.'
        end
        format.json { head :no_content }
      end
    end

    def model_class
      'entitlement'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_entitlement
      @entitlement = Entitlement.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def entitlement_params
      params.expect(entitlement: %i[object_type object_id flag data title username
                                    expires_on]).compact_blank!
    end
  end
end
