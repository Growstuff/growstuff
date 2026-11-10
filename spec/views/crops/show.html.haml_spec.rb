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
    assign(:last_edited_at, @crop.updated_at)
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
        famname:        "Magnoliopsida:Asteridae:Solanales:Solanaceae",
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
    end

    it "shows the optimal temperature as a fact card" do
      render
      expect(rendered).to have_css ".ecocrop-fact", text: "18–32 °C"
    end

    it "renders the taxonomy with line breaks instead of colons" do
      render
      expect(rendered).to have_content "Magnoliopsida"
      expect(rendered).to have_content "Solanaceae"
      expect(rendered).to have_no_content "Magnoliopsida:Asteridae"
      expect(rendered).to include("Magnoliopsida<br>Asteridae<br>Solanales<br>Solanaceae")
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

  context "with first and last harvest medians on an annual" do
    before { @crop.update!(perennial: false, median_days_to_first_harvest: 180, median_days_to_last_harvest: 210) }

    it "shows both in one card" do
      render
      expect(rendered).to have_css ".harvest-window-card", text: /First harvest expected.*26.*Last harvest expected.*30/m
    end
  end

  context "with a last harvest median on a perennial" do
    before { @crop.update!(perennial: true, median_days_to_first_harvest: 180, median_days_to_last_harvest: 210) }

    it "leaves out the last harvest" do
      render
      expect(rendered).to have_no_content "Last harvest expected"
    end
  end

  context "when a crop wrangler views a crop with no EcoCrop record" do
    it "offers to find one" do
      render
      expect(rendered).to have_css "[data-ecocrop-find='#{@crop.id}']"
    end
  end

  context "when the crop is linked to an EcoCrop record" do
    before { @crop.update!(ecocrop_record: create(:ecocrop_data)) }

    it "does not offer to find one" do
      render
      expect(rendered).to have_no_css "[data-ecocrop-find]"
    end
  end

  context "with a harvest style" do
    before { @crop.update!(harvest_style: 'single') }

    it "says the whole plant is harvested" do
      render
      expect(rendered).to have_css ".fact-card", text: "the whole plant is harvested"
    end
  end

  context "without a harvest style" do
    it "has no harvest style block" do
      render
      expect(rendered).to have_no_css ".fact-card", text: "Harvest style"
    end
  end

  context "with a growing degree days figure" do
    before { @crop.update!(growing_degree_days: 650) }

    it "explains what they are" do
      render
      expect(rendered).to have_css "details.growing-degree-days-explainer", text: "one day's worth of useful warmth", visible: :all
    end

    it "gives the crop's figure" do
      render
      expect(rendered).to have_css "details.growing-degree-days-explainer strong", text: "650", visible: :all
    end
  end

  context "without a growing degree days figure or heat data" do
    it "has no explanation" do
      render
      expect(rendered).to have_no_css "details.growing-degree-days-explainer"
    end
  end

  context "when crop does not have matching ecocrop data" do
    it "does not render the ecological requirements table" do
      render
      expect(rendered).to have_no_content "Ecological requirements"
    end
  end
end
