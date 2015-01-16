require 'spec_helper'

describe "crops/search" do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  context "has results" do

    before :each do
      @tomato = FactoryGirl.create(:tomato)
      @roma = FactoryGirl.create(:crop, :name => 'Roma tomato', :parent => @tomato)
      assign(:search, 'tomato')
      assign(:all_matches, [@tomato, @roma])
      render
    end

    it "shows exact matches" do
      assert_select "div#exact_match" do
        assert_select "a[href=#{crop_path(@tomato)}]"
      end
    end

    it "shows all matches" do
      assert_select "div#all_matches" do
        assert_select "a[href=#{crop_path(@roma)}]"
      end
    end
  end

  context "no results" do
    before :each do
      assign(:all_matches, [])
      assign(:search, 'tomato')
      render
    end

    it "tells you there are no matches" do
      rendered.should contain "No results found"
    end

    it "links to browse crops" do
      assert_select "a", :href => crops_path
      rendered.should contain "Try browsing our crop database instead"
    end
  end

end
