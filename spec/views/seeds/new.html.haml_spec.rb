require 'spec_helper'

describe "seeds/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed1 = FactoryGirl.create(:seed, :owner => @member)
    assign(:seed, @seed1)
  end

  it "renders new seed form" do
    render

    assert_select "form", :action => seeds_path, :method => "post" do
      assert_select "select#seed_crop_id", :name => "seed[crop_id]"
      assert_select "textarea#seed_description", :name => "seed[description]"
      assert_select "input#seed_quantity", :name => "seed[quantity]"
      assert_select "input#seed_tradable", :name => "seed[tradable]"
      assert_select "select#seed_tradable_to", :name => "seed[tradable_to]"
    end
  end
end
