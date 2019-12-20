# frozen_string_literal: true

require 'rails_helper'

describe 'Members RSS feed' do
  let(:member) { create :member }

  before { visit member_path(member, format: 'rss') }

  it 'The show action title is what we expect' do
    expect(page).to have_content "#{member.login_name}'s recent posts (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
