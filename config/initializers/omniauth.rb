Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
  provider :flickr, ENV['FLICKR_KEY'], ENV['FLICKR_SECRET']
end
