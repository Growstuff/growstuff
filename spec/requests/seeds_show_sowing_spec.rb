# frozen_string_literal: true

require 'rails_helper'

# What a packet says about sowing, in the packet sheet.
describe SeedsController, '#show' do
  include Devise::Test::IntegrationHelpers

  let(:owner) { create_located_member('Sowing spec southern town', -41.3, 174.8) }
  let(:seed) do
    create(:seed, owner:, sow_months: [10, 11, 12, 1, 2], how_to_sow: "Place seeds 6-8cm apart.\nCover to 2cm.",
                  germination_days_min: 7, germination_days_max: 14)
  end
  let(:page) { Capybara.string(response.body) }

  context 'with what the packet says' do
    before { get seed_path(seed) }

    it('lists when to sow, as a run of months') { expect(page).to have_css('.fact-row .seedfacts--sowmonths', text: 'Oct–Feb') }
    it('lists how to sow') { expect(page).to have_css('.fact-row .seedfacts--howtosow', text: 'Place seeds 6-8cm apart.') }
    it('lists germination as a range of days') { expect(page).to have_css('.fact-row .seedfacts--germination', text: '7–14 days') }

    it('lists them before maturity, in the order they happen') do
      labels = page.all('.packet-facts dt').map(&:text)
      expect(labels.values_at(labels.index('When to sow'), labels.index('Germination'), labels.index('Days until maturity'))).to eq(
        ['When to sow', 'Germination', 'Days until maturity']
      )
    end

    it('keeps the lines of how to sow') { expect(page).to have_css('strong.how-to-sow', text: /apart\.\s*Cover/) }
  end

  context 'with nothing said about sowing' do
    let(:seed) { create(:seed, owner:) }

    before { get seed_path(seed) }

    it('says when to sow is not specified, quietly') do
      expect(page).to have_css('.fact-row.text-muted .seedfacts--sowmonths', text: 'not specified')
    end

    it('says how to sow is not specified, quietly') do
      expect(page).to have_css('.fact-row.text-muted .seedfacts--howtosow', text: 'not specified')
    end

    it('says germination is unknown, quietly') do
      expect(page).to have_css('.fact-row.text-muted .seedfacts--germination', text: 'unknown')
    end
  end

  context 'when the grower looks' do
    before do
      sign_in owner
      get seed_path(seed)
    end

    it('has twelve months to tick in the form that edits everything') do
      expect(page).to have_css('.packet-sheet-form .sow-months-chips input[type=checkbox]', count: 12, visible: :all)
    end

    it('has the months it says ticked') do
      expect(page).to have_css('.packet-sheet-form .sow-months-chips input[checked][value="10"]', visible: :all)
    end

    it('has twelve months in the pencil beside when to sow too') do
      expect(page).to have_css('.fact-row .sow-months-chips input[type=checkbox]', count: 12, visible: :all)
    end

    it('keeps the two sets of chips apart, so each label goes with its own box') do
      ids = page.all('.sow-months-chips input[type=checkbox]', visible: :all).pluck(:id)
      expect(ids.uniq.size).to eq ids.size
    end

    it('has a pencil for each of the three') do
      pencils = page.all('.fact-row a.editable', visible: :all).map { |pencil| pencil.text(:all).strip }
      expect(pencils).to include('Edit sow months', 'Edit how to sow', 'Edit germination days')
    end

    it('offers the seasons as shortcuts, for the grower\'s hemisphere') do
      expect(page).to have_css('.packet-sheet-form [data-sow-months-season="9,10,11"]', text: 'Spring', visible: :all)
    end

    it('asks how to sow in a box of its own') do
      expect(page).to have_css('.packet-sheet-form textarea[name="seed[how_to_sow]"]', visible: :all)
    end
  end

  context 'when the grower is in the northern hemisphere' do
    let(:owner) { create_located_member('Sowing spec northern town', 51.5, -0.1) }

    before do
      sign_in owner
      get seed_path(seed)
    end

    it('has spring as March to May') do
      expect(page).to have_css('.packet-sheet-form [data-sow-months-season="3,4,5"]', text: 'Spring', visible: :all)
    end
  end

  context 'when we do not know where the grower is' do
    let(:owner) { create(:member, location: nil) }

    before do
      sign_in owner
      get seed_path(seed)
    end

    it('has the months to tick') do
      expect(page).to have_css('.packet-sheet-form .sow-months-chips input[type=checkbox]', count: 12, visible: :all)
    end

    it('has no season shortcuts, rather than a guess') { expect(page).to have_no_css('[data-sow-months-season]', visible: :all) }
  end

  context 'when someone else looks' do
    before do
      sign_in create(:member)
      get seed_path(seed)
    end

    it('has no pencils to change it with') { expect(page).to have_no_css('.fact-row .sow-months-chips', visible: :all) }
  end
end
