# frozen_string_literal: true

require 'rails_helper'

describe 'Animal form' do
  include_context 'signed in member'

  before { Feature.find(:domesticated_animals).enable_member(member) }

  context 'when adding an animal from the member profile' do
    before do
      visit member_path(member)
      within('#domesticated-animals') { click_link I18n.t('domesticated_animals.add') }
    end

    it 'opens the form in a dialog' do
      within('[role="dialog"]') do
        expect(page).to have_field('domesticated_animal_name')
      end
    end

    it 'prefills a species in the dialog' do
      within('[role="dialog"]') do
        choose I18n.t('domesticated_animals.categories.rabbit'), allow_label_click: true
        expect(page).to have_field('domesticated_animal_species', with: 'Oryctolagus cuniculus domesticus')
      end
    end

    it 'closes the dialog when cancelled' do
      within('[role="dialog"]') { click_link I18n.t('domesticated_animals.cancel') }
      expect(page).to have_no_css('[role="dialog"]')
    end

    it 'creates the animal from the dialog' do
      within('[role="dialog"]') do
        choose I18n.t('domesticated_animals.categories.rabbit'), allow_label_click: true
        fill_in 'domesticated_animal_name', with: 'Clover'
        choose I18n.t('domesticated_animals.alignments.chaotic_good'), allow_label_click: true
        click_button I18n.t('domesticated_animals.save')
      end
      expect(page).to have_css('.record-page h1', text: 'Clover')
    end

    it 'keeps invalid details in the dialog for correction' do
      within('[role="dialog"]') do
        choose I18n.t('domesticated_animals.categories.rabbit'), allow_label_click: true
        fill_in 'domesticated_animal_name', with: 'Clover'
        fill_in 'domesticated_animal_date_of_birth', with: '2020-02-01'
        find('.animal-advanced-options summary').click
        fill_in 'domesticated_animal_date_of_death', with: '2020-01-01'
        click_button I18n.t('domesticated_animals.save')
        expect(page).to have_css('.invalid-feedback')
      end
    end
  end

  context 'when adding an animal' do
    before { visit new_domesticated_animal_path }

    it 'asks for the category first' do
      within('#new_domesticated_animal') do
        expect(first('select, input:not([type="hidden"])', visible: :all)[:name]).to eq 'domesticated_animal[category]'
      end
    end

    it 'prefills the species from the selected category' do
      choose I18n.t('domesticated_animals.categories.chicken'), allow_label_click: true
      expect(page).to have_field('domesticated_animal_species', with: 'Gallus gallus domesticus')
    end

    it 'updates the suggested species when another category is chosen' do
      choose I18n.t('domesticated_animals.categories.chicken'), allow_label_click: true
      choose I18n.t('domesticated_animals.categories.cat'), allow_label_click: true
      expect(page).to have_field('domesticated_animal_species', with: 'Felis catus')
    end

    it 'allows another kind of animal without a suggested species' do
      choose I18n.t('domesticated_animals.categories.horse'), allow_label_click: true
      choose I18n.t('domesticated_animals.other_category_label'), allow_label_click: true
      expect(page).to have_field('domesticated_animal_species', with: '')
    end

    it 'offers a bio with a prompt' do
      expect(page).to have_field(I18n.t('domesticated_animals.fields.description'),
                                 placeholder: I18n.t('domesticated_animals.bio_placeholder'))
    end

    it 'leaves the alignment unrated initially' do
      expect(page).to have_checked_field('domesticated_animal_alignment_unrated', visible: :all)
    end

    it 'hides the date of death initially' do
      expect(page).to have_no_field('domesticated_animal_date_of_death')
    end

    it 'reveals the date of death when expanded' do
      find('.animal-advanced-options summary').click
      expect(page).to have_field('domesticated_animal_date_of_death')
    end
  end

  context 'when editing an animal with a date of death' do
    let(:animal) { create(:domesticated_animal, owner: member, date_of_death: Date.new(2020, 1, 1)) }

    it 'shows the saved date of death' do
      visit edit_domesticated_animal_path(animal)
      expect(page).to have_field('domesticated_animal_date_of_death', with: '2020-01-01')
    end

    it 'selects the saved category' do
      visit edit_domesticated_animal_path(animal)
      expect(page).to have_checked_field('domesticated_animal_category_chicken', visible: :all)
    end
  end

  context 'when editing an animal with an alignment' do
    let(:animal) { create(:domesticated_animal, owner: member, alignment: 'chaotic_neutral') }

    it 'selects the saved alignment' do
      visit edit_domesticated_animal_path(animal)
      expect(page).to have_checked_field('domesticated_animal_alignment_chaotic_neutral', visible: :all)
    end
  end
end
