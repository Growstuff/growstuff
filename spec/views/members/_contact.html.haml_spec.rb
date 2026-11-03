# frozen_string_literal: true

require 'rails_helper'

describe 'members/_contact' do
  subject { rendered }

  let(:flickr_auth) { nil }
  let(:member) do
    build_stubbed(
      :member,
      website_url: 'https://example.com',
      other_url: 'https://other.example.com',
      instagram_handle: 'grower',
      facebook_handle: 'growerfb',
      bluesky_handle: 'grower.bsky.social',
      show_email: true,
      email: 'grower@example.com'
    )
  end

  before do
    allow(member).to receive(:plantings).and_return([])
    render partial: 'members/contact', locals: { member:, flickr_auth: }
  end

  it 'renders the localized heading' do
    expect(subject).to have_css('h4', text: I18n.t('members.contact.heading'))
  end

  it 'renders the localized website link' do
    expect(subject).to have_link(I18n.t('members.contact.website'), href: member.website_url)
  end

  it 'renders the localized more link' do
    expect(subject).to have_link(I18n.t('members.contact.more'), href: member.other_url)
  end

  context 'with flickr auth present' do
    let(:flickr_auth) { double('Authentication', name: 'Grower Photos', uid: '12345@N01') }

    it 'renders the localized flickr logo alt text' do
      expect(subject).to have_css("img[alt='#{I18n.t('members.contact.flickr_logo')}']")
    end
  end
end
