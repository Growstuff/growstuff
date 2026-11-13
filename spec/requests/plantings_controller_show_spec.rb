# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, '#show' do
  let(:planting) { create(:planting) }
  let(:page) { Capybara.string(response.body) }

  before do
    create(:job, owner: planting.owner, planting:, name: 'Stake the tomatoes')
    get planting_path(planting)
  end

  it 'lists a job planned for the planting, though it has never been crossed off or put back' do
    expect(page).to have_css('.card.job', text: 'Stake the tomatoes')
  end

  it 'displays the short code on the planting show page' do
    expect(page).to have_css('.planting-short-code', text: planting.short_code)
    expect(page).to have_css('.plantingfact--shortcode', text: planting.short_code)
  end
end
