require 'spec_helper'

describe "plantings/edit" do
  before(:each) do
    @right_member = FactoryGirl.create(:member,
      :username => 'right',
      :email => 'right@example.com'
    )
    @wrong_member = FactoryGirl.create(:member,
      :username => 'wrong',
      :email => 'wrong@example.com'
    )

    @crop = FactoryGirl.create(:crop)
    @garden = FactoryGirl.create(:garden, :member => @right_member)

    @planting = assign(:planting,
      FactoryGirl.create(:planting, :garden => @garden, :crop => @crop)
    )

  end

  context "logged out" do
    it "doesn't show the planting form if logged out" do
      render
      rendered.should contain "Only logged in members can do this"
    end
  end

  context "wrong member" do
    before(:each) do
      sign_in @wrong_member
      render
    end

    it "doesn't show the planting form if you don't own it" do
      render
      rendered.should contain "You don't have permission to edit this planting."
    end
  end

  context "logged in" do
    before(:each) do
      sign_in @right_member
      render
    end

    it "renders the edit planting form" do
      assert_select "form", :action => plantings_path(@planting), :method => "post" do
        assert_select "select#planting_garden_id", :name => "planting[garden_id]"
        assert_select "select#planting_crop_id", :name => "planting[crop_id]"
        assert_select "input#planting_quantity", :name => "planting[quantity]"
        assert_select "textarea#planting_description", :name => "planting[description]"
      end
    end
  end
end
