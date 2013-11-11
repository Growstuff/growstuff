require 'spec_helper'

describe 'crops/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    @tomato = FactoryGirl.create(:tomato)
    @maize = FactoryGirl.create(:maize)
    assign(:crops, [@tomato, @maize])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recently added crops"
  end

  it 'shows names of crops' do
    rendered.should contain @tomato.name
    rendered.should contain @maize.name
  end

end
