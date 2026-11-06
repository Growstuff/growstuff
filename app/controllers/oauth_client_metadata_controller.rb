# frozen_string_literal: true

# The document an AT Protocol authorization server fetches to learn who we are:
# its URL is our OAuth client_id.
class OauthClientMetadataController < ApplicationController
  def show
    return head :not_found unless Atproto::ClientConfig.enabled?

    expires_in 1.hour, public: true
    render json: Atproto::ClientConfig.new(request.base_url).metadata
  end
end
