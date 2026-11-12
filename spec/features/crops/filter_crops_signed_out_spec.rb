# frozen_string_literal: true

require 'rails_helper'

describe 'Filtering crops when signed out', :js do
  let!(:tomato) { create(:crop, name: 'tomato') }

  before do
    create(:crop, name: 'roma tomato', parent: tomato)
    create(:crop, name: 'kale')
    visit crops_path
  end

  it 'filters by parent crop' do
    fill_in 'crop-filter-picker', with: 'tomato'
    find('[role=option]', text: 'tomato', match: :first).click
    expect(page).to have_no_content 'kale'
  end
end
