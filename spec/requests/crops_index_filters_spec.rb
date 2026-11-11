# frozen_string_literal: true

require 'rails_helper'

describe 'Crops index filters' do
  include Devise::Test::IntegrationHelpers

  let!(:tomato) { create(:crop, name: 'tomato') }
  let!(:variety) { create(:crop, name: 'roma tomato', parent: tomato) }

  before { create(:crop, name: 'kale') }

  it 'lists the varieties of a parent crop' do
    get crops_path(parent: tomato.id)
    expect(response.body).to include variety.name
  end

  it 'leaves out crops that are not its varieties' do
    get crops_path(parent: tomato.id)
    expect(response.body).not_to include 'kale'
  end

  it 'says so when no crops match' do
    sign_in create(:member)
    get crops_path(history: ['before'])
    expect(response.body).to include 'No crops match those filters.'
  end

  it 'offers a signed out visitor only the parent filter' do
    get crops_path
    expect(response.body).not_to include 'id="filter_history_before"'
  end

  it 'names the member\'s place on the location filter' do
    member = create(:member)
    member.update_columns(location: 'Wellington, New Zealand', latitude: -41.3, longitude: 174.7) # rubocop:disable Rails/SkipsModelValidations
    sign_in member
    get crops_path
    expect(response.body).to include 'Grows well in Wellington'
  end

  it 'tells a signed out visitor they can log in to suggest crops' do
    get crops_path
    expect(response.body).to include 'suggest new crops when you log in'
  end

  it 'does not offer a member who is not a wrangler the data improvement page' do
    sign_in create(:member)
    get crops_path
    expect(response.body).not_to include data_improvement_crops_path
  end

  it 'offers a member the history filter' do
    sign_in create(:member)
    get crops_path
    expect(response.body).to include 'id="filter_history_before"'
  end
end
