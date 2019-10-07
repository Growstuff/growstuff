require 'rails_helper'

describe 'crops/_popover' do
  before do
    @tomato = FactoryBot.create(:tomato)
    @sn = FactoryBot.create(:solanum_lycopersicum, crop: @tomato)
    @planting = FactoryBot.create(:planting, crop: @tomato)
    @tomato.reload
    render partial: 'crops/popover', locals: { crop: @tomato } # to pick up latest plantings_count
  end

  it 'has a scientific name' do
    rendered.should have_content 'Solanum lycopersicum'
  end

  it 'shows count of plantings' do
    rendered.should have_content '1 time'
  end
end
