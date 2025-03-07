# frozen_string_literal: true

module AuditableController
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    include Pagy::Backend

    def history
      raise "No model class defined for #{self.class}" unless defined?(model_class)

      @item_model_class = model_class.to_s.camelize.constantize
      item = @item_model_class.find(params[:id])
      authorize! :history, item

      @item_model_class_name = @item_model_class.to_s.underscore
      versions = @item_model_class.get_versions(params[:id] || params["#{@item_model_class.to_s.underscore}_id"])
      instance_variable_set("@#{@item_model_class.to_s.underscore}",
                            @item_model_class.find(params[:id] || params["#{@item_model_class.to_s.underscore}_id"]))
      @pagy, item_versions = pagy(versions, items: 5)
      instance_variable_set("@#{@item_model_class_name}", item)
      instance_variable_set("@#{@item_model_class_name}_versions", item_versions)

      respond_to do |format|
        format.html { render 'auditable/history' }
        format.json { render json: item_versions }
      end
    end

    def restore
      raise "No model class defined for #{self.class}" unless defined?(model_class)

      item_model_class = model_class.to_s.camelize.constantize
      item = item_model_class.find(params[:id])
      authorize! :restore, item

      snapshot = ActiveSnapshot::Snapshot.find(params[:version_id])

      respond_to do |format|
        if snapshot.restore!
          format.html do
            redirect_to send("history_#{item_model_class.to_s.underscore}_url", params[:id]),
                        notice: 'Item was successfully restored.'
          end
          format.json do
            render :show, status: :ok, location: send("history_#{item_model_class.to_s.underscore}_url", params[:id])
          end
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: item.errors, status: :unprocessable_entity }
        end
      end
    end
  end
end
