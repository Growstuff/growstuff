require 'spec_helper'

describe "gardens/show" do
  before(:each) do
    @owner = FactoryGirl.create(:member)
    @garden = assign(:garden, FactoryGirl.create(:garden, :owner => @owner))
  end

  context 'logged out' do
    it 'should not show the edit button' do
      render
      rendered.should_not contain 'Edit'
    end
  end

  context 'signed in' do

    before :each do
      sign_in @owner
      render
    end

    it 'should have an edit button' do
      rendered.should contain 'Edit'
    end

    it "shows a 'plant something' button" do
      rendered.should contain "Plant something"
    end

    it "links to the right crop in the planting link" do
      assert_select("a[href=#{new_planting_path}?garden_id=#{@garden.id}]")
    end
  end

end
