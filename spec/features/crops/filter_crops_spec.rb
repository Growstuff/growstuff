# frozen_string_literal: true

require 'rails_helper'

describe 'Filtering crops', :js do
  let(:member) { create(:member) }
  let!(:tomato) { create(:crop, name: 'tomato') }

  before do
    create(:crop, name: 'roma tomato', parent: tomato)
    create(:crop, name: 'kale')
    login_as member
    visit crops_path
  end

  it 'narrows the list as soon as a filter changes' do
    fill_in 'crop-filter-picker', with: 'tomato'
    find('[role=option]', text: 'tomato', match: :first).click
    expect(page).to have_no_content 'kale'
  end

  it 'keeps the filter in the address' do
    fill_in 'crop-filter-picker', with: 'tomato'
    find('[role=option]', text: 'tomato', match: :first).click
    expect(page).to have_current_path(/parent=\d+/)
  end
end
