require 'rails_helper'

describe "scientific_names/edit" do
  context "logged in" do
    before(:each) do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @scientific_name = assign(:scientific_name,
        FactoryBot.create(:zea_mays))
      render
    end

    it "shows the creator" do
      rendered.should have_content "Added by #{@scientific_name.creator} less than a minute ago."
    end

    it "renders the edit scientific_name form" do
      assert_select "form", action: scientific_names_path(@scientific_name), method: "post" do
        assert_select "input#scientific_name_name", name: "scientific_name[scientific_name]"
        assert_select "select#scientific_name_crop_id", name: "scientific_name[crop_id]"
      end
    end
  end
end
