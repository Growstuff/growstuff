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
    it 'starts with one row' do
      expect(page).to have_css '#alternate_names .template', count: 1
    end

    it 'adds a row' do
      click_button class: 'add-altname-row'
      expect(page).to have_css '#alternate_names .template', count: 2
    end

    it 'numbers the added row' do
      click_button class: 'add-altname-row'
      expect(page).to have_field 'alt_name[2]'
    end

    it 'removes the last row' do
      click_button class: 'add-altname-row'
      click_button class: 'remove-altname-row'
      expect(page).to have_css '#alternate_names .template', count: 1
    end

    it 'keeps the first row' do
      click_button class: 'remove-altname-row'
      expect(page).to have_css '#alternate_names .template', count: 1
    end
  end
end
