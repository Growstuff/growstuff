require 'rails_helper'

describe 'Members RSS feed' do
  let(:member) { create :member }

  before { visit member_path(member, format: 'rss') }

  pending 'The show action exists' do
    # expect(page.status_code).to equal 200
  end

  it 'The show action title is what we expect' do
    expect(page).to have_content "#{member.login_name}'s recent posts (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
