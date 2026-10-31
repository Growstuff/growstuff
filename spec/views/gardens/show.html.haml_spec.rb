# frozen_string_literal: true

require 'rails_helper'

describe "gardens/show" do
  context 'when the garden is active' do
    before do
      @owner = create(:member)
      controller.stub(:current_user) { @owner }
      allow(view).to receive_messages(member_signed_in?: true, current_member: @owner)
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

    it 'shows the planting as a garden card' do
      assert_select '.garden-planting .garden-planting-name', text: @planting.display_name
    end

    it 'credits the planting to its grower' do
      assert_select '.garden-planting .garden-planting-by a[href=?]', member_path(@owner)
    end

    it 'lists the actions in the order the design has them' do
      expect(rendered).to match(/Edit.*Add photo from Flickr.*Plant something here.*New job.*Make this a nursery.*Mark as inactive/m)
    end

    it 'leaves out the sign-up banner' do
      assert_select '.garden-join-banner', count: 0
    end

    it 'puts the layout before growing now for the owner' do
      assert_select '.garden-layout-section ~ .garden-plantings'
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

    it 'puts the facts above the layout' do
      assert_select '.gardenfacts ~ .garden-layout-section'
    end

    it 'leads to the layout page from the section bar' do
      assert_select ".garden-layout-section .section-header a[href=?]", layout_member_garden_path(@owner, @garden), text: 'edit layout'
    end

    it 'pitches the layout tool with a New badge when the garden has no layout' do
      assert_select ".garden-layout-section .badge", text: 'New'
    end

    it 'invites the owner to map out the bed' do
      expect(rendered).to have_content "Map out this bed"
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

    it 'shows the bed map' do
      assert_select ".garden-layout-section svg.garden-layout-teaser-svg"
    end

    it 'counts the plants placed on the bed' do
      assert_select ".garden-layout-headline", text: '0 plants placed on the bed'
    end

    it 'has no New badge' do
      assert_select ".garden-layout-section .badge", count: 0
    end

    it 'offers to edit the layout' do
      assert_select ".garden-layout-section .section-add", text: 'edit layout'
    end
  end

  context 'when viewing another member active garden with a layout' do
    before do
      @owner = create(:member)
      @viewer = create(:member)
      controller.stub(:current_user) { @viewer }
      allow(view).to receive_messages(current_member: @viewer, member_signed_in?: true)
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
      assert_select '.record-grower-follow button', text: "Follow #{@owner}"
    end

    it 'offers to view the layout' do
      assert_select ".garden-layout-section .section-add", text: 'view layout'
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
      assign(:photo_count, 2)
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'shows the photos section with an add link' do
      assert_select '.photos .section-add'
    end

    it 'leads the panel with the garden photo, counting the photos' do
      assert_select '.garden-detail > a.garden-hero[href=?]', garden_photos_path(garden), text: /2 photos/
    end

    it 'links to the rest of the photos' do
      assert_select '.photos a[href=?]', garden_photos_path(garden), text: 'More photos'
    end
  end

  context 'when nobody is signed in' do
    let(:garden) { create(:garden, latitude: -41.29, longitude: 174.78) }

    before do
      controller.stub(:current_user) { nil }
      allow(view).to receive_messages(member_signed_in?: false, current_member: nil)
      create(:job, garden: garden, name: 'Sow the beans', due_date: Time.zone.today)
      assign(:public_jobs, JobsNotepad.new(nil, garden: garden))
      assign(:garden, garden)
      assign(:current_plantings, [])
      assign(:finished_plantings, [])
      assign(:suggested_companions, [])
      render
    end

    it 'says what Growstuff is' do
      assert_select '.garden-join-banner h2', text: 'Growstuff is where people share what they grow'
    end

    it 'asks them to sign in to follow the owner' do
      assert_select '.record-grower-follow a[aria-label=?]', "Sign in to follow #{garden.owner}"
    end

    it 'lists the garden\'s jobs' do
      assert_select '.garden-notepad .notepad-job .notepad-name', text: 'Sow the beans'
    end

    it 'has no tick boxes on the jobs' do
      assert_select '.garden-notepad .notepad-box', count: 0
    end

    it 'names the season where the garden is' do
      assert_select '.garden-season', text: /\A(Spring|Summer|Autumn|Winter)\z/
    end

    it 'invites them to join, near the description' do
      assert_select '.garden-join-prompt a', text: 'Join free'
    end

    it 'offers to start their own garden' do
      assert_select '.garden-start .section-header h2', text: 'Start your own garden'
    end

    it 'shows the growing now section before the layout' do
      assert_select '.garden-plantings ~ .garden-layout-section'
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

      assert_select ".garden-layout-section", count: 0
    end
  end
end
