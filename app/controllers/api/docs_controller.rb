# frozen_string_literal: true

module Api
  # The API's own description, for Swagger UI at /api-docs.
  class DocsController < ActionController::API
    def show
      render json: ApiDocs.openapi
    end
  end
end
