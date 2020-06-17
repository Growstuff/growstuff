#!/usr/bin/env ruby
# frozen_string_literal: true

require "English"

# NOTE: circleci docs are here:
# https://circleci.com/docs/2.0/env-vars/#built-in-environment-variables

puts "Checking to see if you're in CONTRIBUTORS.md..."

if ENV['TRAVIS'] || ENV['CI']
  if ENV['TRAVIS_PULL_REQUEST'] || ENV['CIRCLE_PULL_REQUEST']
    require 'httparty'
    repo = "#{ENV['TRAVIS_REPO_SLUG']}#{ENV['CIRCLE_PROJECT_REPONAME']}"
    pr = "#{ENV['TRAVIS_PULL_REQUEST']}#{ENV['CIRCLE_PR_NUMBER']}"
    url = "https://api.github.com/repos/#{repo}/pulls/#{pr}"
    response = HTTParty.get(url).parsed_response
    author = response['user']['login'] if response && response['user']

    # Could not determine author
    exit unless author
  else
    # We're in a Travis branch build; nothing to check
    exit
  end
else
  author = `git config github.user`.chomp
  if $CHILD_STATUS.exitstatus.positive?
    abort %(
Couldn't determine your GitHub username, and not in a Travis PR build
Please set it using
    git config --add github.user [username]
)
  end
end

# Escape chars in name, and make case insensitive
author_to_search_for = Regexp.new(Regexp.escape(author), Regexp::IGNORECASE)

unless File.read('CONTRIBUTORS.md').match?(author_to_search_for)
  abort %(
Thanks for your contribution, #{author}!
Please add your name and GitHub handle to the file CONTRIBUTORS.md,
commit it, and update your PR.
  )
end
