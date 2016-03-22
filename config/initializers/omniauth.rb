Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, SECRETS.GROWSTUFF_TWITTER_KEY, SECRETS.GROWSTUFF_TWITTER_SECRET
  provider :flickr, SECRETS.GROWSTUFF_FLICKR_KEY, SECRETS.GROWSTUFF_FLICKR_SECRET
end
