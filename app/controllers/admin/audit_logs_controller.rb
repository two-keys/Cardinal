# frozen_string_literal: true

module Admin
  class AuditLogsController < Admin::AdminPanelController
    include Pagy::Backend

    def index
      query = ActiveSnapshot::Snapshot.order(created_at: :desc).includes(:user, :item)

      # Apply filters
      query = query.where(item_type: params[:item_type]) if params[:item_type].present?
      user = User.find_by(username: params[:whodunnit])
      query = query.where(user_id: user.id) if user.present?
      query = query.where("metadata ->> 'event' = ?", params[:event]) if params[:event].present?

      query = query.where(created_at: Date.parse(params[:date_from]).beginning_of_day..) if params[:date_from].present?

      query = query.where(created_at: ..Date.parse(params[:date_to]).end_of_day) if params[:date_to].present?

      @pagy, @versions = pagy(query, items: 25)
    end

    def show
      @version = PaperTrail::Version.find(params[:id])
      @user = User.find_by(id: @version.user)
      @item = @version.item_type.constantize.find_by(id: @version.item_id) if @version.item_id
    end
  end
end
