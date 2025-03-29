# frozen_string_literal: true

module TaggableController
  extend ActiveSupport::Concern

  # there's probably a better way to do this but my brain is fried
  included do
    before_action :set_tag_schema, only: %i[create update_tags]
  end

  private

  def set_tag_schema
    @tag_schema = TagSchema.get_schema(controller_name)
  end

  def tag_params
    # logger.debug "#{controller_name} my schema name is '#{@tag_schema.name}'"

    params.require(:tags).permit(**@tag_schema.allowed_type_params)
  end
end
