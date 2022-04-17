# frozen_string_literal: true

class SchemaController < ApplicationController
  # GET /schema/types
  def types
    render json: CardinalSettings::Tags.types, status: :ok
  end
end
