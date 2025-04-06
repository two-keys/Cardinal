# frozen_string_literal: true

class SchemaController < ApplicationController
  # GET /schema/types.json
  def types
    render json: TagSchema.allowed_polarities, status: :ok
  end
end
