# frozen_string_literal: true

require 'rails_helper'

describe "crops/show" do
  before do
    @crop = FactoryBot.create(:maize)
    @posts = []
    assign(:crop, @crop)
    @member = FactoryBot.create(:crop_wrangling_member)
    sign_in @member
    @current_member = @member
    @harvest = FactoryBot.create :harvest, owner: @member
    controller.stub(:current_user) { @member }
  end

  it "hides sunniness block if no sunniness" do
    render
    expect(rendered).not_to have_content "Sunniness"
  end

  it "has sunniness block if sunny planting" do
    FactoryBot.create(:sunny_planting, crop: @crop)
    render
    expect(rendered).to have_content "Sunniness"
  end

  it "hides planted from block if no planted_from" do
    render
    expect(rendered).not_to have_content "Planted from"
  end

  it "has planted from block if seed planting" do
    FactoryBot.create(:seed_planting, crop: @crop)
    render
    expect(rendered).to have_content "Planted from"
  end

  it "hides harvested block if no harvests" do
    render
    expect(rendered).not_to have_content "Harvested for"
  end

  it "has harvested block if harvest" do
    @crop.harvests << @harvest
    render
    expect(rendered).to have_content "Harvested for"
  end
end
