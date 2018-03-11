require 'rails_helper'

describe "plantings/show" do
  let(:crop) { FactoryBot.create(:tomato) }
  let(:member) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden, owner: member) }
  let(:planting) do
    FactoryBot.create(:planting, garden: garden, crop: crop,
                                 owner: garden.owner,
                                 planted_from: 'cutting')
  end

  before(:each) do
    assign(:planting, planting)
    assign(:photos, planting.photos.paginate(page: 1))
    controller.stub(:current_user) { member }
  end

  context 'sunniness' do
    let(:planting) { FactoryBot.create(:sunny_planting) }

    it "shows the sunniness" do
      render
      rendered.should have_content 'Sun or shade?'
      rendered.should have_content 'sun'
    end
  end

  context 'planted from' do
    let(:planting) { FactoryBot.create(:cutting_planting) }

    it "shows planted_from" do
      render
      rendered.should have_content 'Planted from:'
      rendered.should have_content 'cutting'
    end

    it "shows planted_from if blank" do
      planting.update(planted_from:  '')
      render
      rendered.should have_content 'Planted from: not specified'
    end
  end

  it "shows photos" do
    photo = FactoryBot.create(:photo, owner: member)
    planting.photos << photo
    render
    assert_select "img[src='#{photo.thumbnail_url}']"
  end

  it "shows a link to add photos" do
    render
    rendered.should have_content "Add photo"
  end

  context "no location set" do
    before(:each) do
      render
    end

    it "renders the quantity planted" do
      rendered.should match(/3/)
    end

    it "renders the description" do
      rendered.should match(/This is a/)
    end

    it "renders markdown in the description" do
      assert_select "em", "really"
    end

    it "doesn't contain a () if no location is set" do
      rendered.should_not have_content "()"
    end
  end

  context "location set" do
    before(:each) do
      planting.owner.update(location: 'Greenwich, UK')
      render
    end

    it "shows the member's location in parentheses" do
      rendered.should have_content "(#{planting.owner.location})"
    end
  end
end
