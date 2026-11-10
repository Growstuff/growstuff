# frozen_string_literal: true

require 'rails_helper'

describe MembersController, '#show location' do
  subject(:page) { Capybara.string(response.body) }

  before { get member_path(member) }

  context 'with a location' do
    let(:member) { create(:london_member) }

    it { is_expected.to have_link(href: place_path(member.location), class: nil, text: 'Greenwich, UK') }
  end

  context 'without a location' do
    let(:member) { create(:member) }

    it { is_expected.to have_no_css('.badge-location') }
  end
end
