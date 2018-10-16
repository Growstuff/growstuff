require 'rails_helper'

describe "crops/edit" do
  before(:each) do
    controller.stub(:current_user) do
      FactoryBot.create(:crop_wrangling_member)
    end
    @crop = FactoryBot.create(:maize)
    3.times do
      @crop.scientific_names.build
    end
    assign(:crop, @crop)
    render
  end

  it "shows the creator" do
    expect(rendered).to have_content "Added by\n#{@crop.creator}\nless than a minute\nago."
  end
end
