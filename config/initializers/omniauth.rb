# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV['GROWSTUFF_TWITTER_KEY'], ENV['GROWSTUFF_TWITTER_SECRET']
  provider :flickr, ENV['GROWSTUFF_FLICKR_KEY'], ENV['GROWSTUFF_FLICKR_SECRET']
end
