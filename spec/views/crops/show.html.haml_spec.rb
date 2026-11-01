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

  context "when the crop is a variety with no photos of its own and its parent has photos" do
    let(:parent_crop) { create(:crop, name: "Potato") }
    let(:variety) { create(:crop, name: "Rua Potato", parent: parent_crop) }
    let(:parent_photo) { create(:photo, owner: @member) }

    before do
      PhotoAssociation.create!(photo: parent_photo, photographable: parent_crop)
      assign(:crop, variety)
    end

    it "does not render the parent crop's photos" do
      render
      expect(rendered).to have_no_xpath("//img[contains(@src,'#{parent_photo.fullsize_url}')]")
    end
  end
end
