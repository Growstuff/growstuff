# frozen_string_literal: true

require 'rails_helper'

# The facts of a packet, as the packet sheet lists them.
describe SeedsController, '#show' do
  include Devise::Test::IntegrationHelpers

  let(:seed) do
    create(:seed, batch_number: 'LYIG0403', organic: 'certified organic', gmo: 'certified GMO-free', heirloom: 'heirloom')
  end
  let(:page) { Capybara.string(response.body) }

  context 'with what the packet claims' do
    before { get seed_path(seed) }

    it('lists the batch number') { expect(page).to have_css('.fact-row .seedfacts--batchnumber', text: 'LYIG0403') }
    it('lists whether it is organic') { expect(page).to have_css('.fact-row .seedfacts--organic', text: 'Certified organic') }
    it('lists whether it is GMO free') { expect(page).to have_css('.fact-row .seedfacts--gmo', text: 'Certified GMO-free') }
    it('names each by a label') { expect(page).to have_css('.packet-facts dt', text: /\A(Batch number|Organic|GMO)\z/, count: 3) }
    it('says what it says, not in muted type') { expect(page).to have_no_css('.fact-row.text-muted .seedfacts--organic') }
  end

  context 'with nothing known' do
    let(:seed) { create(:seed, batch_number: nil, organic: 'unknown', gmo: 'unknown') }

    before { get seed_path(seed) }

    it('says the batch number is not specified') do
      expect(page).to have_css('.fact-row.text-muted .seedfacts--batchnumber', text: 'not specified')
    end

    it('says organic is unknown, quietly') { expect(page).to have_css('.fact-row.text-muted .seedfacts--organic', text: 'Unknown') }
    it('says GMO is unknown, quietly') { expect(page).to have_css('.fact-row.text-muted .seedfacts--gmo', text: 'Unknown') }
  end

  context 'when the grower looks' do
    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it('has a pencil for each of the new facts') do
      pencils = page.all('.fact-row a.editable', visible: :all).map { |pencil| pencil.text(:all).strip }
      expect(pencils).to include('Edit batch number', 'Edit organic', 'Edit gmo')
    end

    it('edits the batch number as text') { expect(page).to have_css('.fact-row input[name="seed[batch_number]"]', visible: :all) }

    it('edits organic as a choice') do
      expect(page).to have_css('.fact-row select[name="seed[organic]"] option', count: Seed::ORGANIC_VALUES.size, visible: :all)
    end

    it('edits GMO as a choice') do
      expect(page).to have_css('.fact-row select[name="seed[gmo]"] option', count: Seed::GMO_VALUES.size, visible: :all)
    end
  end

  context 'when someone else looks' do
    before do
      sign_in create(:member)
      get seed_path(seed)
    end

    it('has no pencils') { expect(page).to have_no_css('.fact-row a.editable', visible: :all) }
  end
end
