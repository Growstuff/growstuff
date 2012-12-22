require 'spec_helper'

describe "plantings/edit" do
  before(:each) do
    @right_user = User.create!(
      :username => 'right',
      :email => "growstuff@example.com",
      :password => 'irrelevant',
      :tos_agreement => true
    )
    @right_user.confirm!

    @wrong_user = User.create!(
      :username => 'wrong',
      :email => "growstuff2@example.com",
      :password => 'irrelevant',
      :tos_agreement => true
    )
    @wrong_user.confirm!

    @garden = assign(:garden, stub_model(Garden,
      :id => 1,
      :user => @right_user,
      :name => "Blah"
    ))
    @planting = assign(:planting, stub_model(Planting,
      :garden_id => 1,
      :crop_id => 1,
      :quantity => 1,
      :description => "MyText"
    ))

    assign(:crop, Crop.new)
    assign(:garden, Garden.new)

  end

  context "logged out" do
    it "doesn't show the planting form if logged out" do
      render
      rendered.should contain "Only logged in users can do this"
    end
  end

  context "wrong user" do
    before(:each) do
      sign_in @wrong_user
      render
    end

    it "doesn't show the planting form if you don't own it" do
      render
      rendered.should contain "You don't have permission to edit this planting."
    end
  end

  context "logged in" do
    before(:each) do
      sign_in @right_user
      render
    end

    it "renders the edit planting form" do
      render

      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", :action => plantings_path(@planting), :method => "post" do
        assert_select "select#planting_garden_id", :name => "planting[garden_id]"
        assert_select "select#planting_crop_id", :name => "planting[crop_id]"
        assert_select "input#planting_quantity", :name => "planting[quantity]"
        assert_select "textarea#planting_description", :name => "planting[description]"
      end
    end
  end
end
