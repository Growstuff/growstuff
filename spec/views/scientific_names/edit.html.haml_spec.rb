# frozen_string_literal: true

require 'rails_helper'

describe "scientific_names/edit" do
  context "logged in" do
    let(:member)          { FactoryBot.create(:member)                    }
    let(:scientific_name) { FactoryBot.create(:zea_mays, creator: member) }

    before do
      sign_in member
      controller.stub(:current_user) { member }
      assign(:scientific_name, scientific_name)
      render
    end

    it "shows the creator" do
      expect(rendered).to have_content "Added by #{member} less than a minute ago."
    end
    it { expect(rendered).to have_link member }

    it "renders the edit scientific_name form" do
      assert_select "form", action: scientific_names_path(scientific_name), method: "post" do
        assert_select "input#scientific_name_name", name: "scientific_name[scientific_name]"
        assert_select "select#scientific_name_crop_id", name: "scientific_name[crop_id]"
      end
    end
  end
end
