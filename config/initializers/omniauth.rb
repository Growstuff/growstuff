Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV['GROWSTUFF_TWITTER_KEY'], ENV['GROWSTUFF_TWITTER_SECRET']
  provider :flickr, ENV['GROWSTUFF_FLICKR_KEY'], ENV['GROWSTUFF_FLICKR_SECRET']
  provider :facebook, ENV['GROWSTUFF_FACEBOOK_KEY'], ENV['GROWSTUFF_FACEBOOK_SECRET'], :scope => 'name,email', :display => 'popup'
end
