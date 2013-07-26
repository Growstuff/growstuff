require 'spec_helper'

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
    assert_select "tr>td", :text => @seed1.crop.system_name, :count => 2
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
    end
  end
end
