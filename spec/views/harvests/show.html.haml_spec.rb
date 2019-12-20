# frozen_string_literal: true

require 'rails_helper'

describe "harvests/show" do
  subject { render }

  let!(:harvest) { FactoryBot.create(:harvest) }

  before do
    controller.stub(:current_user) { nil }
    assign(:harvest, harvest)
    assign(:photos, harvest.photos.paginate(page: 1))
    render
  end

  describe "renders attributes" do
    it { is_expected.to have_content harvest.crop.name }
    it { is_expected.to have_content I18n.l(harvest.harvested_at) }
    it { is_expected.to have_content harvest.plant_part.to_s }
  end
end
