#!/usr/bin/env ruby

puts "Checking to see if you're in CONTRIBUTORS.md..."
if ENV['TRAVIS']
  if ENV['TRAVIS_PULL_REQUEST']
    require 'httparty'
    repo = ENV['TRAVIS_REPO_SLUG']
    pr = ENV['TRAVIS_PULL_REQUEST']
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

unless system('grep', '-i', author, 'CONTRIBUTORS.md')
  abort %(
Thanks for your contribution, #{author}!
Please add your name and GitHub handle to the file CONTRIBUTORS.md,
commit it, and update your PR.
  )
end
