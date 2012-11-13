require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'links to the crops page' do
    rendered.should contain 'Crops'
  end

  it 'links to the updates page' do
    rendered.should contain 'Recent updates'
  end

  it 'should have description' do
    render
    rendered.should contain 'Growstuff is a community of food gardeners'
    rendered.should contain 'We welcome you regardless of your experience, and invite you to be part of our development process.'
  end
end
