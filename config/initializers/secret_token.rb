# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Growstuff::Application.config.secret_token = ENV['RAILS_SECRET_TOKEN'] || "this is not a real secret token but it's here to make life easier for developers"
