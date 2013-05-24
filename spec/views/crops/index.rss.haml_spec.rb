require 'spec_helper'

describe 'crops/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    assign(:crops, [
      FactoryGirl.create(:tomato),
      FactoryGirl.create(:maize)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recently added crops"
  end

  it 'shows names of crops' do
    rendered.should contain "Tomato"
    rendered.should contain "Maize"
  end

end
