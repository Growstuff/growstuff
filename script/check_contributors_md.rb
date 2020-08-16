#!/usr/bin/env ruby
# frozen_string_literal: true

require "English"

if ENV['CI']
  if ENV['GITHUB_EVENT_NAME'] == 'pull_request'
    author = ENV['GITHUB_ACTOR']
    exit 1 unless author

  elsif ENV['TRAVIS_PULL_REQUEST']
    require 'httparty'
    repo = ENV['TRAVIS_REPO_SLUG']
    pr = ENV['TRAVIS_PULL_REQUEST']
    url = "https://api.github.com/repos/#{repo}/pulls/#{pr}"
    response = HTTParty.get(url).parsed_response
    author = response['user']['login'] if response && response['user']

    # Could not determine author
    exit 1 unless author
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

puts("Checking for #{author} in CONTRIBUTORS.md")

unless File.read('CONTRIBUTORS.md').match?(author_to_search_for)
  abort %(
Thanks for your contribution, #{author}!
Please add your name and GitHub handle to the file CONTRIBUTORS.md,
commit it, and update your PR.
  )
end
