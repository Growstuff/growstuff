# frozen_string_literal: true

require 'rails_helper'

# What a seed's own page says of the packet in its photos.
describe SeedsController, '#show' do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed) }
  let(:photo) { create(:photo, owner: seed.owner) }

  before { seed.photo_associations.create!(photo:, label: 'back') }

  context 'when its owner looks at the label of a photo' do
    let(:page) { Capybara.string(response.body) }

    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it('lights the side it is') { expect(page).to have_css('.packet-label .btn.active', text: 'Back') }
    it('does not make the side it is a link') { expect(page).to have_no_css('.packet-label a', text: 'Back') }
    it('offers to make it the front') { expect(page).to have_link('Front', href: /label=front/) }
    it('offers to say it is not of the packet') { expect(page).to have_link('None', href: /label=(&|$)/) }
    it('does not add a badge as well') { expect(page).to have_no_css('.packet-label .badge') }
  end

  context 'with the text read from the packet' do
    let(:page) { Capybara.string(response.body) }
    let(:text) { "Approx 15 seeds per packet\nSow by: December 2026" }
    let(:panel) { '.packet-sheet .col-lg-6 .seed-packet-panel' }

    before do
      seed.update!(packet_text: text)
      get seed_path(seed)
    end

    it('shows it in the panel beside the facts, to anyone') do
      expect(page).to have_css("#{panel} .seed-packet-text", text: 'Sow by: December 2026')
    end

    it('keeps its lines') { expect(page.find("#{panel} pre", visible: :all).native.text).to eq text }

    it('labels it as our attempt to read the packet') { expect(page).to have_css("#{panel} h3", text: 'Our attempt to read the packet') }
    it('says it is automatic, and makes mistakes') { expect(page).to have_css("#{panel} p", text: 'Read automatically', visible: :all) }

    it('names the text by that label, for a screen reader') do
      label_id = page.find("#{panel} pre", visible: :all)['aria-labelledby']
      expect(page).to have_css("##{label_id}", text: 'Our attempt to read the packet', visible: :all)
    end

    it('keeps it behind a button') do
      expect(page).to have_css("#{panel} button.seed-packet-text-toggle[aria-expanded=false]", text: 'Show our attempt to read the packet')
    end

    it('has it folded away until asked for') { expect(page).to have_css("#{panel} .collapse:not(.show) pre", visible: :all) }
    it('has the facts in the other column') { expect(page).to have_css('.packet-sheet .col-lg-6 .packet-facts') }

    context 'when the text has markup in it' do
      let(:text) { '<script>alert(1)</script> Sow by: 2026' }

      it('shows the markup as text, not as markup') { expect(page).to have_no_css('.seed-packet-panel script', visible: :all) }
      it('still shows what it said') { expect(page.find("#{panel} pre").native.text).to eq text }
    end
  end

  context 'with a photo of the packet but no text yet' do
    let(:page) { Capybara.string(response.body) }

    before { get seed_path(seed) }

    it('shows the photo in the panel') do
      expect(page).to have_css('.packet-sheet .seed-packet-photos a[title="Back of packet"]')
    end

    it('has no text box') { expect(page).to have_no_css('.seed-packet-text') }
    it('has no label for text that is not there') { expect(page).to have_no_text('Our attempt to read the packet') }
  end

  context 'with both sides of the packet photographed' do
    let(:page) { Capybara.string(response.body) }

    before do
      seed.photo_associations.create!(photo: create(:photo, owner: seed.owner), label: 'front')
      get seed_path(seed)
    end

    it('switches between them, front first') { expect(page).to have_css('.seed-packet-switch .nav-link.active', text: 'Front') }
    it('has the back to switch to') { expect(page).to have_css('.seed-packet-switch .nav-link', text: 'Back') }
    it('shows one at a time') { expect(page).to have_css('.seed-packet-photos .tab-pane', count: 2, visible: :all) }
    it('gives each a bigger copy to zoom to') { expect(page).to have_css('.seed-packet-photos img[data-large]', count: 2, visible: :all) }
  end

  context 'with one side of the packet photographed' do
    let(:page) { Capybara.string(response.body) }

    before { get seed_path(seed) }

    it('has nothing to switch between') { expect(page).to have_no_css('.seed-packet-switch') }
  end

  context 'with neither photos of the packet nor text' do
    let(:page) { Capybara.string(response.body) }
    let(:bare) { create(:seed) }

    before { get seed_path(bare) }

    it('has no panel') { expect(page).to have_no_css('.seed-packet-panel') }
    it('gives the facts the whole width') { expect(page).to have_css('.packet-sheet .col-12 .packet-facts') }
  end

  context 'when its owner looks' do
    let(:page) { Capybara.string(response.body) }

    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it('offers to edit all of the facts') { expect(page).to have_css('.packet-sheet .section-header button', text: 'Edit all') }

    it('has the form in the sheet, hidden until asked for') do
      expect(page).to have_css('.packet-sheet form.packet-sheet-form #seed_variety', visible: :all)
    end

    it('has the form beside the packet, not over it') do
      expect(page).to have_css('.packet-sheet .col-lg-6 form.packet-sheet-form', visible: :all)
    end

    it('has no dialog any more') { expect(page).to have_no_css('#seed-edit-modal', visible: :all) }

    it('makes the menu\'s Edit work without JavaScript, by going to the form\'s page') do
      expect(page).to have_css("a[href='#{edit_seed_path(seed)}'][data-packet-sheet-edit]", visible: :all)
    end
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
