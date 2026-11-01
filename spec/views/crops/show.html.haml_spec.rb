# frozen_string_literal: true

require 'rails_helper'

describe "crops/show" do
  before do
    @crop = create(:maize)
    @posts = []
    assign(:crop, @crop)
    @member = create(:crop_wrangling_member)
    sign_in @member
    @current_member = @member
    @harvest = create(:harvest, owner: @member)
    controller.stub(:current_user) { @member }
    assign(:version_members, {})
  end

  it "hides sunniness block if no sunniness" do
    render
    expect(rendered).to have_no_content "Sunniness"
  end

  it "has sunniness block if sunny planting" do
    create(:sunny_planting, crop: @crop)
    render
    expect(rendered).to have_content "Sunniness"
  end

  it "hides planted from block if no planted_from" do
    render
    expect(rendered).to have_no_content "Planted from"
  end

  it "has planted from block if seed planting" do
    create(:seed_planting, crop: @crop)
    render
    expect(rendered).to have_content "Planted from"
  end

  it "hides harvested block if no harvests" do
    render
    expect(rendered).to have_no_content "Harvested for"
  end

  it "has harvested block if harvest" do
    @crop.harvests << @harvest
    render
    expect(rendered).to have_content "Harvested for"
  end

  context "when crop has matching ecocrop data" do
    before do
      EcocropData.create!(
        ecoportcode:    1234,
        scientificname: "Zea mays",
        topmn:          18,
        topmx:          32,
        ropmn:          600,
        ropmx:          1200
      )
      @crop.scientific_names.create!(name: "Zea mays", creator: @member)
    end

    it "renders the ecological requirements table" do
      render
      expect(rendered).to have_content "Ecological requirements"
      expect(rendered).to have_content "Optimal temperature"
      expect(rendered).to have_content "18 - 32 °C"
    end

    it "renders the CC-BY-4.0 license link" do
      render
      expect(rendered).to have_link("CC-BY-4.0", href: "https://creativecommons.org/licenses/by/4.0/")
    end

    it "renders the required citation" do
      render
      citation = [
        "Food and Agriculture Organization of the United Nations (2025) ECOCROP, the crop ecological requirements database. Version 1.",
        "https://data.apps.fao.org/catalog/dataset/ecocrop. Accessed through the CGIAR Climate Action Data Hub,",
        "https://cgiar-climate-data-hub.github.io/catalog/ecocrop_1/."
      ].join(' ')
      expect(rendered).to have_content(citation)
    end
  end

  context "when crop does not have matching ecocrop data" do
    it "does not render the ecological requirements table" do
      render
      expect(rendered).to have_no_content "Ecological requirements"
    end
  end
end
