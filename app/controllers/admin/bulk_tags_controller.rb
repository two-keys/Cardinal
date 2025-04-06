# frozen_string_literal: true

require 'csv'

module Admin
  class BulkTagsController < Admin::AdminPanelController
    include Pagy::Backend

    def index
      @csv = CSV.generate do |csv|
        csv << Tag.attribute_names
      end
    end

    def update # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
      csv = CSV.parse(upload_params.read, headers: true, converters: %i[numeric])
      @failures = []
      successes = []

      csv.each do |row| # rubocop:disable Metrics/BlockLength
        tag = Tag.find_by(id: row['id'])
        @failures << { id: row['id'] } unless tag
        next unless tag

        needs_synonym_update = tag.synonym_id != row['synonym_id']&.to_i
        needs_parent_update = tag.ancestry != row['ancestry']

        begin
          unless tag.update(row)
            @failures << tag
            Rails.logger.debug { "Failures: #{@failures.count}" }
          end
        rescue StandardError
          @failures << tag
          next
        end

        successes << tag
        Rails.logger.debug { "Successes: #{successes.count}" }

        if needs_synonym_update
          ObjectTag.where(tag_id: tag.id).update_all(tag_id: row['synonym_id']) # rubocop:disable Rails/SkipsModelValidations
        end

        next unless needs_parent_update

        object_tags = ObjectTag.where(tag_id: tag.id)
        object_tags.find_each do |object_tag|
          object_tag.object.tags << tag.parent if tag.parent
        rescue StandardError
          next
        end
      end

      respond_to do |format|
        format.html do
          redirect_to admin_bulk_tags_path, notice: "#{successes.count} Tags have been updated",
                                            alert: @failures.count.positive? ? "Tags of ID #{@failures.map(&:id)} have failed to update" : nil # rubocop:disable Layout/LineLength
        end
        format.json { head :no_content }
      end
    end

    def download
      all_tags = Tag.all
      data = Rails.cache.fetch('tags_download', expires_in: 1.hour) do
        export_to_csv(all_tags)
      end
      send_data(data, filename: 'tags.csv')
    end

    def export_to_csv(tags)
      CSV.generate do |csv|
        csv << Tag.attribute_names
        tags.each do |tag|
          csv << tag.attributes.values
        end
      end
    end

    def upload_params
      params.require(:upload)
    end
  end
end
