require 'spec_helper'

describe "scientific_names/edit" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @scientific_name = assign(:scientific_name,
      FactoryGirl.create(:zea_mays)
    )
  end

  context "logged in" do
    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      render
    end

    it "renders the edit scientific_name form" do
      render
      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", :action => scientific_names_path(@scientific_name), :method => "post" do
        assert_select "input#scientific_name_scientific_name", :name => "scientific_name[scientific_name]"
        assert_select "input#scientific_name_crop_id", :name => "scientific_name[crop_id]"
      end
    end
  end

end
