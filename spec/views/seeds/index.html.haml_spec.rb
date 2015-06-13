## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "seeds/index" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed1 = FactoryGirl.create(:seed, :owner => @member)
    @page = 1
    @per_page = 2
    @total_entries = 2
    seeds = WillPaginate::Collection.create(@page, @per_page, @total_entries) do |pager|
      pager.replace([ @seed1, @seed1 ])
    end
    assign(:seeds, seeds)
  end

  it "renders a list of seeds" do
    render
    assert_select "tr>td", :text => @seed1.crop.name, :count => 2
    assert_select "tr>td", :text => @seed1.owner.login_name, :count => 2
    assert_select "tr>td", :text => @seed1.quantity.to_s, :count => 2
  end

  context "tradable" do
    before(:each) do
      @owner = FactoryGirl.create(:london_member)
      @seed1 = FactoryGirl.create(:tradable_seed, :owner => @owner)
      seeds = WillPaginate::Collection.create(@page, @per_page, @total_entries) do |pager|
        pager.replace([ @seed1, @seed1 ])
      end
      assign(:seeds, seeds)
      render
    end

    it "shows tradable seeds" do
      assert_select "tr>td", :text => @seed1.tradable_to, :count => 2
    end

    it "shows location of seed owner" do
      assert_select "tr>td", :text => @owner.location, :count => 2
      assert_select 'a', :href => place_path(@owner.location)
    end
  end

  it "provides data links" do
    render
    rendered.should have_content "The data on this page is available in the following formats:"
    assert_select "a", :href => seeds_path(:format => 'csv')
    assert_select "a", :href => seeds_path(:format => 'json')
    assert_select "a", :href => seeds_path(:format => 'rss')
  end
end
