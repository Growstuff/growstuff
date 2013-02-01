require 'spec_helper'

describe "gardens/edit" do

  context "logged in" do
    before(:each) do
      controller.stub(:current_user) { Member.new }
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
        assert_select "textarea#garden_description", :name => "garden[description]"
      end
    end
  end

end
