# frozen_string_literal: true

require 'rails_helper'

describe 'Posts RSS feed' do
  it 'The index feed exists' do
    visit posts_path(format: 'rss')
    # expect(page.status_code).to equal 200
  end

  it 'The index title is what we expect' do
    visit posts_path(format: 'rss')
    expect(page).to have_content "Recent posts from "\
      "#{@author || 'all members'} (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
