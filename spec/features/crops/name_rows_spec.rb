# frozen_string_literal: true

require 'rails_helper'

describe 'Name fields on the crop form', :js do
  include_context 'signed in crop wrangler'

  shared_examples 'a list of name fields' do |noun, field|
    let(:add_label) { "Add #{noun.downcase}" }

    it 'starts with one field' do
      expect(page).to have_field "#{field}[1]"
    end

    it 'adds a field' do
      click_button add_label
      expect(page).to have_field "#{field}[2]"
    end

    it 'removes the chosen field' do
      click_button add_label
      fill_in "#{field}[1]", with: 'first'
      fill_in "#{field}[2]", with: 'second'
      click_button "Remove #{noun.downcase} 1"
      expect(page).to have_field "#{field}[1]", with: 'second'
    end

    it 'renumbers the fields after one is removed' do
      click_button add_label
      click_button "Remove #{noun.downcase} 1"
      expect(page).to have_no_field "#{field}[2]"
    end

    it 'keeps the only field' do
      expect(page).to have_button "Remove #{noun.downcase} 1", disabled: true
    end
  end

  context 'with a new crop' do
    before { visit new_crop_path }

    describe 'alternate names' do
      it_behaves_like 'a list of name fields', 'Alternate name', 'alt_name'
    end

    describe 'scientific names' do
      it_behaves_like 'a list of name fields', 'Scientific name', 'sci_name'
    end
  end

  context 'with a crop that has names' do
    let(:crop) { create(:crop) }

    before do
      create(:alternate_name, crop:, name: 'Sampaguita')
      create(:scientific_name, crop:, name: 'Jasminum sambac')
      visit edit_crop_path(crop)
    end

    it 'shows the existing alternate names' do
      expect(page).to have_field 'alt_name[1]', with: 'Sampaguita'
    end

    it 'shows the existing scientific names' do
      expect(page).to have_field 'sci_name[1]', with: 'Jasminum sambac'
    end
  end

  describe 'suggesting scientific names' do
    let(:suggestions) do
      [{ 'key' => 1, 'canonicalName' => 'Zea mays', 'scientificName' => 'Zea mays L.', 'rank' => 'SPECIES' },
       { 'key' => 2, 'canonicalName' => 'Zea mexicana', 'scientificName' => 'Zea mexicana (Schrad.) Kuntze', 'rank' => 'SPECIES' }]
    end

    before do
      allow(GbifService).to receive(:new).and_return(instance_double(GbifService, suggest: suggestions))
      visit new_crop_path
      fill_in 'sci_name[1]', with: 'Zea'
    end

    it 'lists the matches' do
      expect(page).to have_css '[role=option]', text: 'Zea mays (Zea mays L.) – SPECIES'
    end

    it 'fills in the chosen match' do
      find('[role=option]', text: 'Zea mexicana').click
      expect(page).to have_field 'sci_name[1]', with: 'Zea mexicana'
    end

    it 'closes the list once one is chosen' do
      find('[role=option]', text: 'Zea mexicana').click
      expect(page).to have_no_css '[role=option]'
    end

    it 'chooses the highlighted match with the keyboard' do
      expect(page).to have_css '[role=option]', count: 2
      find_by_id('sci_name[1]').send_keys(:down, :enter)
      expect(page).to have_field 'sci_name[1]', with: 'Zea mays'
    end
  end
end
