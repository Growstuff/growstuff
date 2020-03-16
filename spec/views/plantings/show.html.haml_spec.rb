# frozen_string_literal: true

require 'rails_helper'

describe "plantings/show" do
  let(:crop)   { FactoryBot.create(:tomato)                }
  let(:member) { FactoryBot.create(:member)                }
  let(:garden) { FactoryBot.create(:garden, owner: member) }
  let(:planting) do
    FactoryBot.create(:planting, garden: garden, crop: crop,
                                 owner: garden.owner,
                                 planted_from: 'cutting')
  end

  before do
    assign(:planting, planting)
    assign(:photos, planting.photos.paginate(page: 1))
    assign(:neighbours, planting.nearby_same_crop)
    controller.stub(:current_user) { member }
  end

  context 'sunniness' do
    let(:planting) { FactoryBot.create(:sunny_planting) }

    describe "shows the sunniness" do
      before { render }
      it { expect(rendered).to have_content 'Planted in' }
      it { expect(rendered).to have_content 'sun' }
    end
  end

  context 'planted from' do
    let(:planting) { FactoryBot.create(:cutting_planting) }

    describe "shows planted_from" do
      before { render }
      it { expect(rendered).to have_content 'Grown from' }
      it { expect(rendered).to have_content 'cutting' }
    end

    describe "shows planted_from if blank" do
      before do
        planting.update(planted_from: '')
        render
      end
      it { expect(rendered).not_to have_content 'Planted from' }
    end
  end

  it "shows photos" do
    photo1 = FactoryBot.create(:photo, owner: member)
    photo2 = FactoryBot.create(:photo, owner: member)
    planting.photos << photo1
    planting.photos << photo2
    render
    assert_select "img[src='#{photo1.fullsize_url}']"
    assert_select "img[src='#{photo2.fullsize_url}']"
  end

  describe "shows a link to add photos" do
    before { render }
    it { expect(rendered).to have_content "Add photo" }
  end

  context "no location set" do
    before { render }

    it "renders the quantity planted" do
      expect(rendered).to match(/3/)
    end

    it "renders the description" do
      expect(rendered).to match(/This is a/)
    end

    it "renders markdown in the description" do
      assert_select "em", "really"
    end

    it "doesn't contain a () if no location is set" do
      expect(rendered).not_to have_content "()"
    end
  end

  context "location set" do
    before do
      planting.owner.update(location: 'Greenwich, UK')
      render
    end

    it "shows the member's location in parentheses" do
      expect(rendered).to have_content planting.owner.location.to_s
    end
  end
end
