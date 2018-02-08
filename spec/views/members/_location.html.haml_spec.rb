require 'rails_helper'

describe "members/_location" do
  context "member with location" do
    let(:member) { FactoryBot.create(:london_member) }

    before(:each) { render partial: 'members/location', locals: { member: member } }

    it 'shows location if available' do
      expect(rendered).to have_content member.location
    end

    it "links to the places page" do
      assert_select "a", href: place_path(member.location)
    end
  end

  context "member with no location" do
    before(:each) do
      member = FactoryBot.create(:member)
      render partial: 'members/location', locals: { member: member }
    end

    it 'shows unknown location' do
      expect(rendered).to have_content "unknown location"
    end

    it "doesn't link anywhere" do
      assert_select "a", false
    end
  end
end
