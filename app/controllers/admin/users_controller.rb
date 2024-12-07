# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    include Pagy::Backend
    include ApplicationHelper

    before_action :require_admin
    before_action :set_user, only: %i[show edit update destroy]

    # GET /admin/users or /admin/users.json
    def index
      @pagy, @users = pagy(User.all, items: 5)
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show; end

    # GET /admin/users/new
    def new
      @user = User.new
    end

    # GET /admin/users/1/edit
    def edit
      @pagy_sent_reports, @sent_reports = pagy(@user.sent_reports, items: 5, page: params[:made_reports_page])
      @pagy_received_reports, @received_reports = pagy(@user.received_reports, items: 5,
                                                                               page: params[:received_reports_page])
      @pagy_handled_reports, @handled_reports = pagy(@user.handled_reports, items: 5,
                                                                            page: params[:handled_reports_page])
    end

    # POST /admin/users or /admin/users.json
    def create
      @user = User.new(user_params)
      # TODO: Remove this when we're ready to deploy with a real email server.
      @user.skip_confirmation_notification!

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

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :verified, :unban_at,
                                   :ban_reason, :delete_at)
    end
  end
end
