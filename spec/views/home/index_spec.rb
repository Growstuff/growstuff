require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  before(:each) do
    assign(:crop_count, 2)
    assign(:update_count, 1337)
    assign(:member_count, 42)
    render
  end
  
  it 'links to the crops page' do
    rendered.should contain 'Crops'
  end
  
  it 'counts the number of crops' do
    rendered.should contain '(2)'
  end
  
  it 'links to the updates page' do
    rendered.should contain 'Recent updates'
  end
  
  it 'counts the number of updates' do
    rendered.should contain '(1337)'
  end
  
  it 'links to the members page' do
    rendered.should contain 'Members'
  end
  
  it 'counts the number of members' do
    rendered.should contain '(42)'
  end
  
  it 'should have description' do
    render
    rendered.should contain 'Growstuff is a community of food gardeners'
    rendered.should contain 'We welcome you regardless of your experience, and invite you to be part of our development process.'
  end
end
