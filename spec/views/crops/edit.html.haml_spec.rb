require 'rails_helper'

describe 'crops/edit' do
  before do
    controller.stub(:current_user) { FactoryBot.create(:crop_wrangling_member) }
    @crop = FactoryBot.create(:maize)
    3.times { @crop.scientific_names.build }
    assign(:crop, @crop)
    render
  end

  it 'shows the creator' do
    expect(rendered).to have_content "Added by #{@crop.creator} less than a minute ago."
  end
end
