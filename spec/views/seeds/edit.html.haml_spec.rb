require 'spec_helper'

describe "seeds/edit" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed = FactoryGirl.create(:seed, :owner => @member)
  end

  it "renders the edit seed form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => seeds_path(@seed), :method => "post" do
      assert_select "select#seed_crop_id", :name => "seed[crop_id]"
      assert_select "textarea#seed_description", :name => "seed[description]"
      assert_select "input#seed_quantity", :name => "seed[quantity]"
    end
  end
end
