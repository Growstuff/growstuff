require 'rails_helper'

describe 'harvests/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member = FactoryBot.create(:member)
    @tomato = FactoryBot.create(:tomato)
    @maize  = FactoryBot.create(:maize)
    @pp = FactoryBot.create(:plant_part)
    assign(:harvests, harvests)
    render
  end

  context 'all harvests' do
    before(:each) do
      #assign(:harvest, FactoryBot.create(:harvest))
      render
    end

    it 'shows RSS feed title' do
      rendered.should have_content "Recent harvests from all members"
    end

    it 'item title shows owner and crop' do
      rendered.should have_content "#{@harvest.crop}"
    end

    # it 'shows formatted content of posts' do
    #   rendered.should have_content "This is a <em>really</em> good plant."
    # end
    #
    # it 'shows sunniness' do
    #   rendered.should have_content 'Sunniness: sun'
    # end
    #
    # it 'shows propagation method' do
    #   rendered.should have_content 'Planted from: seedling'
    # end
  end

  # context "one person's plantings" do
  #   before :each do
  #     @planting = FactoryBot.create(:planting)
  #     assign(:plantings, [@planting])
  #     assign(:owner, @planting.owner)
  #     render
  #   end
  #
  #   it 'shows title for single member' do
  #     rendered.should have_content "Recent plantings from #{@planting.owner}"
  #   end
  # end
end
