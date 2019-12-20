# frozen_string_literal: true

require 'rails_helper'

describe "seeds/new" do
  let!(:seed)   { FactoryBot.create(:seed, owner: member) }
  let!(:member) { FactoryBot.create(:member)              }

  before do
    sign_in member
    controller.stub(:current_user) { @member }
    assign(:seed, seed)
    render
  end

  it "renders new seed form" do
    assert_select "form", action: seeds_path, method: "post" do
      assert_select "input#crop", class: "ui-autocomplete-input"
      assert_select "input#seed_crop_id", name: "seed[crop_id]"
      assert_select "textarea#seed_description", name: "seed[description]"
      assert_select "input#seed_quantity", name: "seed[quantity]"
      assert_select "select#seed_tradable_to", name: "seed[tradable_to]"
    end
  end

  context 'member has no location' do
    describe 'reminds you to set your location' do
      it { expect(rendered).to have_content "Don't forget to set your location." }
      it { expect(rendered).to have_link "set your location" }
    end
  end

  context 'when member has location' do
    let!(:member) { FactoryBot.create(:london_member) }

    describe 'shows the location' do
      it { expect(rendered).to have_text "from #{member.location}." }
      it { expect(rendered).to have_link(member.location, href: place_path(member.location)) }
    end

    it 'link to change location' do
      expect(rendered).to have_link("Change your location.")
    end
  end
end
