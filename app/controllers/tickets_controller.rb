# frozen_string_literal: true

class TicketsController < ApplicationController
  include Pagy::Backend
  include ApplicationHelper

  before_action :authenticate_user!
  before_action :set_ticket, only: %i[show destroy]

  after_action :track_create, only: :create

  authorize_resource

  # GET /tickets
  # GET /tickets.json
  def index
    @pagy, @tickets = pagy(Ticket.accessible_by(current_ability).includes(:user), items: 5)
  end

  # GET /tickets/1
  # GET /tickets/1.json
  def show; end

  # DELETE /tickets/1
  # DELETE /tickets/1.json
  def destroy
    respond_to do |format|
      if @ticket.destroy!
        format.html { redirect_to tickets_url, notice: 'Ticket was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Saves us having to find tag by route params
  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def auth_redirect
    tickets_path
  end

  def track_create
    ahoy.track 'Ticket Created', { user_id: @ticket.user.id, item_id: @ticket.item_id, item_type: @ticket.item_type }
  end
end
