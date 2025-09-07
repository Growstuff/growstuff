# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV.fetch('GROWSTUFF_TWITTER_KEY', nil), ENV.fetch('GROWSTUFF_TWITTER_SECRET', nil)
  provider :flickr, ENV.fetch('GROWSTUFF_FLICKR_KEY', nil), ENV.fetch('GROWSTUFF_FLICKR_SECRET', nil), scope: 'read'
end
