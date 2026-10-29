# frozen_string_literal: true

require 'rails_helper'

# What a seed's own page says of the packet in its photos.
describe SeedsController, '#show' do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed) }
  let(:photo) { create(:photo, owner: seed.owner) }

  before { seed.photo_associations.create!(photo:, label: 'back') }

  context 'when its owner looks' do
    let(:page) { Capybara.string(response.body) }

    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it('lights the side it is') { expect(page).to have_css('.packet-label .btn.active', text: 'Back') }
    it('does not make the side it is a link') { expect(page).to have_no_link('Back') }
    it('offers to make it the front') { expect(page).to have_link('Front', href: /label=front/) }
    it('offers to say it is not of the packet') { expect(page).to have_link('None', href: /label=(&|$)/) }
    it('does not add a badge as well') { expect(page).to have_no_css('.packet-label .badge') }
  end

  context 'with the text read from the packet' do
    let(:page) { Capybara.string(response.body) }
    let(:text) { "Approx 15 seeds per packet\nSow by: December 2026" }

    before do
      seed.update!(packet_text: text)
      get seed_path(seed)
    end

    it('shows it, folded away, to anyone') { expect(page).to have_css('details summary', text: 'Text from the packet') }
    it('keeps its lines') { expect(page.find('details pre', visible: :all).native.text).to eq text }

    context 'when the text has markup in it' do
      let(:text) { '<script>alert(1)</script> Sow by: 2026' }

      it('shows the markup as text, not as markup') { expect(page).to have_no_css('details script', visible: :all) }
      it('still shows what it said') { expect(page.find('details pre', visible: :all).native.text).to eq text }
    end
  end

  context 'without text read from the packet' do
    let(:page) { Capybara.string(response.body) }

    before { get seed_path(seed) }

    it('has no section for it') { expect(page).to have_no_css('details', text: 'Text from the packet') }
  end

  context 'when someone else looks' do
    let(:page) { Capybara.string(response.body) }

    before do
      sign_in create(:member)
      get seed_path(seed)
    end

    it('says it is the back of the packet') { expect(page).to have_css('.packet-label .badge', text: 'Back of packet') }
    it('offers no changes') { expect(page).to have_no_css('.packet-label .btn') }
  end
end
