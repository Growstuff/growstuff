require 'spec_helper'

describe "gardens/edit" do

  context "logged out" do
    it "doesn't show the garden editing form if logged out" do
      render
      rendered.should contain "Only logged in members can do this"
    end
  end

  context "logged in" do
    before(:each) do
      @owner = FactoryGirl.create(:member)
      sign_in @owner
      @garden = assign(:garden, FactoryGirl.create(:garden, :owner => @owner))
      render
    end

    it "renders the edit garden form" do
      render

      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", :action => gardens_path(@garden), :method => "post" do
        assert_select "input#garden_name", :name => "garden[name]"
      end
    end
  end

end
