require 'spec_helper'

describe "crops/edit" do
  before(:each) do
    @crop = assign(:crop, stub_model(Crop,
      :system_name => "MyString",
      :en_wikipedia_url => "MyString"
    ))
  end

  context "logged out" do
    it "doesn't show the crop form if logged out" do
      render
      rendered.should contain "Only logged in users can do this"
    end
  end

  context "logged in" do
    before(:each) do
      @user = User.create(:email => "growstuff@example.com", :password => "irrelevant")
      @user.confirm!
      sign_in @user
      render
    end

    it "renders the edit crop form" do
      render
      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", :action => crops_path(@crop), :method => "post" do
        assert_select "input#crop_system_name", :name => "crop[system_name]"
        assert_select "input#crop_en_wikipedia_url", :name => "crop[en_wikipedia_url]"
      end
    end
  end
end
