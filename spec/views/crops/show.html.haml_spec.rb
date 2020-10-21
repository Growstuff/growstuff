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

  it "hides sunniness block iff no sunniness" do
    render
    expect(rendered).not_to have_content "Sunniness"

    FactoryBot.create(:sunny_planting, crop: @crop)
    assign(:crop, @crop)
    render
    expect(rendered).to have_content "Sunniness"
  end

  it "hides planted from block iff no planted_from" do
    render
    expect(rendered).not_to have_content "Planted from"

    FactoryBot.create(:seed_planting, crop: @crop)
    assign(:crop, @crop)
    render
    expect(rendered).to have_content "Planted from"
  end

  it "hides harvesting block iff no harvests" do
    render
    expect(rendered).not_to have_content "Harvested for"

    @crop.harvests << @harvest
    assign(:crop, @crop)
    render
    expect(rendered).to have_content "Harvested for"
  end
end

