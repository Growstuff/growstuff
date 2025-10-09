# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :flickr, ENV.fetch('GROWSTUFF_FLICKR_KEY', nil), ENV.fetch('GROWSTUFF_FLICKR_SECRET', nil), scope: 'read'
end
