# frozen_string_literal: true

require 'rails_helper'

describe 'members/_contact.html.haml', type: :view do
  let(:member) { create(:member) }
  let(:authentication) do
    build_stubbed(:mastodon_authentication, name: ['@alice', 'mastodon.social'].join('@'))
  end

  before do
    render partial: 'members/contact', locals: { member:, flickr_auth: nil, mastodon_auths: [authentication] }
  end

  it 'links to the Mastodon profile' do
    expect(rendered).to have_link('alice', href: 'https://mastodon.social/@alice')
  end

  it 'uses only the username as the link label' do
    expect(rendered).not_to have_text(['@alice', 'mastodon.social'].join('@'))
  end

  it 'opens the profile safely in a new tab' do
    expect(rendered).to have_css('a[href="https://mastodon.social/@alice"][target="_blank"][rel="noopener noreferrer"]')
  end
end
