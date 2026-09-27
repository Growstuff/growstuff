# frozen_string_literal: true

require 'rails_helper'

describe "gardens/show" do
  context 'when the garden is active' do
    before do
      @owner = create(:member)
      controller.stub(:current_user) { @owner }
      @garden = create(:garden, owner: @owner)
      @planting = create(:planting, garden: @garden, owner: @garden.owner)
      @suggested_companions = create_list(:crop, 4)
      assign(:garden, @garden)
      assign(:current_plantings, [@planting])
      assign(:finished_plantings, [])
      assign(:suggested_companions, @suggested_companions)
      render
    end

    it 'shows the location' do
      expect(rendered).to have_content @garden.location
    end

    it 'shows the area' do
      expect(rendered).to have_content pluralize(@garden.area, @garden.area_unit)
    end

    it 'shows the description' do
      expect(rendered).to have_content "totally cool garden"
    end

    it 'renders markdown in the description' do
      assert_select "strong", "totally"
    end

    it 'shows plantings on the garden page' do
      expect(rendered).to have_content @planting.crop.name
    end

    it 'points people at the garden layout' do
      assert_select "a.garden-layout-teaser[href=?]", layout_member_garden_path(@owner, @garden)
    end
  end

  context 'when the garden is inactive' do
    it "doesn't offer the layout, as nothing is growing there to place" do
      garden = create(:inactive_garden)
      controller.stub(:current_user) { garden.owner }
      assign(:garden, garden)
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render

      assert_select "a.garden-layout-teaser", count: 0
    end
  end
end
