# frozen_string_literal: true

require 'rails_helper'

describe 'members/_map' do
  subject { rendered }

  context 'when member has coordinates and location' do
    let(:member) { build_stubbed(:london_member) }

    before do
      render partial: 'members/map', locals: { member: }
    end

    it 'renders the map container' do
      expect(subject).to have_css('#membermap.member-map')
    end

    it 'links to the places page anchor' do
      expect(subject).to have_link(member.location, href: place_path(member.location, anchor: 'members'))
    end

    it 'renders the localized nearby text' do
      expect(subject).to have_content(
        I18n.t(
          'members.map.see_nearby_html',
          location: member.location
        ).gsub(/<[^>]*>/, '')
      )
    end
  end

  context 'when member does not have coordinates' do
    let(:member) { build_stubbed(:member, latitude: nil, longitude: nil) }

    before do
      render partial: 'members/map', locals: { member: }
    end

    it 'renders the location not set container' do
      expect(subject).to have_css('.location-not-set')
    end

    it 'renders the localized heading' do
      expect(subject).to have_css('h1', text: I18n.t('members.map.not_known'))
    end

    it 'renders the localized explanation' do
      expect(subject).to have_css('p', text: I18n.t('members.map.cant_show_nearby'))
    end
  end
end
