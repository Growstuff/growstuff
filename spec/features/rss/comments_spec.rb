# frozen_string_literal: true

require 'rails_helper'

describe 'Comments RSS feed' do
  it 'The index feed exists' do
    visit comments_path(format: 'rss')
    # expect(page.status_code).to equal 200
  end

  it 'The index title is what we expect' do
    visit comments_path(format: 'rss')
    expect(page).to have_content "Recent comments on all posts (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
