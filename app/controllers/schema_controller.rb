# frozen_string_literal: true

class SchemaController < ApplicationController
  # GET /schema/types
  def types
    render json: TagSchema::TAG_SCHEMA_HASH, status: :ok
  end
end
