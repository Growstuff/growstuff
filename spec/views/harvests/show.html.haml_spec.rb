require 'rails_helper'

describe "harvests/show" do
  let!(:harvest) { FactoryBot.create(:harvest) }

  before do
    controller.stub(:current_user) { nil }
    assign(:harvest, harvest)
    render
  end

  subject { render }

  describe "renders attributes" do
    it { is_expected.to have_content harvest.crop.name }
    it { is_expected.to have_content harvest.harvested_at.to_s }
    it { is_expected.to have_content harvest.plant_part.to_s }
  end
end
