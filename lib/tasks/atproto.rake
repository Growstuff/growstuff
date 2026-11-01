# frozen_string_literal: true

namespace :atproto do
  desc 'Print a new signing key for GROWSTUFF_ATPROTO_PRIVATE_KEY, which turns on sign in with Bluesky'
  task generate_key: :environment do
    puts Atproto::Jws.generate_key.to_pem.gsub("\n", '\n')
  end
end
