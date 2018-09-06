require 'rails_helper'

feature 'Members RSS feed' do
  let(:member) { create :member }

  scenario 'The show action exists' do
    visit member_path(member, format: 'rss')
    expect(page.status_code).to equal 200
  end

  scenario 'The show action title is what we expect' do
    visit member_path(member, format: 'rss')
    expect(page).to have_content "#{member.login_name}'s recent posts (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
