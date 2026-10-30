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

    it 'links the breadcrumb to the garden itself' do
      expect(view.content_for(:breadcrumbs)).to have_link(@garden.name, href: garden_path(@garden))
    end

    it 'shows how many plantings are growing now' do
      assert_select '.fact-growing', text: '1'
    end

    it 'shows harvests this year' do
      assert_select '.fact-harvested', text: '0'
    end

    it 'shows the area' do
      assert_select '.fact-area', text: '23'
    end

    it 'lets the owner edit the description inline' do
      assert_select '.garden-edit-row .garden-description + .edit-link a.editable'
    end

    it 'lets the owner edit the area inline' do
      assert_select '.fact-card a.editable[data-display=?]', '.fact-area-value'
    end

    it 'lets the owner rename the garden inline' do
      assert_select 'a.editable[data-display=?]', '.garden-title'
    end

    it 'opens the plant dialog from the add on the plantings' do
      assert_select '[data-react-component=GardenPlanter]'
    end

    it 'shows the area unit' do
      expect(rendered).to have_content 'acres'
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

    it 'points people at the garden layout teaser with New indicator when garden has no layout' do
      assert_select "a.garden-layout-teaser[href=?]", layout_member_garden_path(@owner, @garden)
      expect(rendered).to have_content "New"
      expect(rendered).to have_content "Map out this bed"
      expect(rendered).to have_content "Try out the new garden layout tool"
    end
  end

  context 'when the garden is active and has a layout' do
    before do
      @owner = create(:member)
      controller.stub(:current_user) { @owner }
      @garden = create(:garden, owner: @owner, layout_saved_at: Time.current)
      @planting = create(:planting, garden: @garden, owner: @garden.owner)
      assign(:garden, @garden)
      assign(:current_plantings, [@planting])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'shows the layout SVG preview and edit controls without New badge' do
      assert_select "a.garden-layout-teaser[href=?]", layout_member_garden_path(@owner, @garden)
      assert_select "svg.garden-layout-teaser-svg"
      expect(rendered).not_to have_content "New"
      expect(rendered).to have_content "Garden layout"
      expect(rendered).to have_content "Edit layout →"
    end
  end

  context 'when viewing another member active garden with a layout' do
    before do
      @owner = create(:member)
      @viewer = create(:member)
      controller.stub(:current_user) { @viewer }
      allow(view).to receive(:current_member).and_return(@viewer)
      @garden = create(:garden, owner: @owner, layout_saved_at: Time.current)
      assign(:garden, @garden)
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'marks the jobs as public' do
      assert_select '.garden-jobs-public', text: 'Public'
    end

    it 'offers to follow the owner' do
      assert_select '.record-grower-follow .member-card-follow'
    end

    it 'shows view layout controls' do
      expect(rendered).to have_content "Garden layout"
      expect(rendered).to have_content "View layout →"
    end
  end

  context 'when the member has a jobs notepad on their garden' do
    let(:garden) { create(:garden) }

    before do
      controller.stub(:current_user) { garden.owner }
      allow(view).to receive(:current_member).and_return(garden.owner)
      assign(:garden, garden)
      assign(:notepad, JobsNotepad.new(garden.owner, garden: garden))
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'is not wrapped in a second bordered section' do
      assert_select 'section .notepad', count: 0
    end

    it 'titles the notepad with the garden' do
      assert_select '.notepad .notepad-title h2', text: "Jobs in #{garden.name}"
    end
  end

  context 'when the garden has a collaborator' do
    let(:garden) { create(:garden) }
    let(:collaborator) { create(:member) }

    before do
      create(:garden_collaborator, garden: garden, member: collaborator)
      controller.stub(:current_user) { garden.owner }
      assign(:garden, garden)
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'links the collaborator' do
      assert_select '.garden-collaborators a[href=?]', member_path(collaborator)
    end

    it 'shows the collaborator avatar' do
      assert_select '.garden-collaborators img.garden-person-avatar'
    end
  end

  context 'when the garden has wikidata temperatures' do
    let(:garden) { create(:garden, location_wikidata_id: 'Q1', highest_temp_c: 31.4, lowest_temp_c: 3.1) }

    before do
      controller.stub(:current_user) { garden.owner }
      assign(:garden, garden)
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'shows both temperatures on one line' do
      assert_select '.garden-temperatures', text: /hottest 31\.4°C, coldest 3\.1°C/
    end
  end

  context 'when the garden has more photos than the page shows' do
    let(:garden) { create(:garden) }
    let(:photos) { create_list(:photo, 2, owner: garden.owner) }

    before do
      photos.each { |photo| garden.photos << photo }
      controller.stub(:current_user) { garden.owner }
      assign(:garden, garden)
      assign(:photos, [photos.first])
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'shows the photos section with an add link' do
      assert_select '.photos .section-add'
    end

    it 'counts the photos beside the garden picture' do
      assert_select '.card-image + .card-body a[href=?]', garden_photos_path(garden), text: '2 photos'
    end

    it 'links to the rest of the photos' do
      assert_select '.photos a[href=?]', garden_photos_path(garden), text: 'More photos'
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
