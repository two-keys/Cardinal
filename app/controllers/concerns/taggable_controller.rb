# frozen_string_literal: true

module TaggableController
  extend ActiveSupport::Concern

  def tag_schema
    @tag_schema || (@tag_schema = TagSchema.get_schema(controller_name))
  end

  private

  def tag_params
    # logger.debug "#{controller_name} my schema name is '#{tag_schema.name}'"

    params.require(:tags).permit(**tag_schema.allowed_type_params)
  end
end
