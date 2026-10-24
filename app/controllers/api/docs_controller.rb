# frozen_string_literal: true

module Api
  # The API's own description, for Swagger UI at /api-docs.
  class DocsController < ActionController::API
    def show
      expires_in 1.hour, public: true
      render json: ApiDocs.openapi
    end
  end
end
