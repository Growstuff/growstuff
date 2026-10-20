# frozen_string_literal: true

require 'rails_helper'

describe 'Name rows on the crop form', :js do
  include_context 'signed in crop wrangler'

  before { visit new_crop_path }

  context 'with scientific names' do
    it 'starts with one row' do
      expect(page).to have_css '#scientific_names .template', count: 1
    end

    it 'adds a row' do
      click_button class: 'add-sciname-row'
      expect(page).to have_css '#scientific_names .template', count: 2
    end

    it 'numbers the added row' do
      click_button class: 'add-sciname-row'
      expect(page).to have_field 'sci_name[2]'
    end

    it 'removes the last row' do
      click_button class: 'add-sciname-row'
      click_button class: 'remove-sciname-row'
      expect(page).to have_css '#scientific_names .template', count: 1
    end

    it 'keeps the first row' do
      click_button class: 'remove-sciname-row'
      expect(page).to have_css '#scientific_names .template', count: 1
    end
  end

  context 'with alternate names' do
    it 'starts with one field' do
      expect(page).to have_field 'alt_name[1]'
    end

    it 'adds a field' do
      click_button 'Add alternate name'
      expect(page).to have_field 'alt_name[2]'
    end

    it 'removes the chosen field' do
      click_button 'Add alternate name'
      fill_in 'alt_name[1]', with: 'Sampaguita'
      fill_in 'alt_name[2]', with: 'Manol'
      click_button 'Remove alternate name 1'
      expect(page).to have_field 'alt_name[1]', with: 'Manol'
    end

    it 'renumbers the fields after one is removed' do
      click_button 'Add alternate name'
      click_button 'Remove alternate name 1'
      expect(page).to have_no_field 'alt_name[2]'
    end

    it 'keeps the only field' do
      expect(page).to have_button 'Remove alternate name 1', disabled: true
    end
  end

  context 'with a crop that has alternate names' do
    let(:crop) { create(:crop) }

    before do
      create(:alternate_name, crop:, name: 'Sampaguita')
      visit edit_crop_path(crop)
    end

    it 'shows the existing names' do
      expect(page).to have_field 'alt_name[1]', with: 'Sampaguita'
    end
  end
end
