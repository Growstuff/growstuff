require 'spec_helper'

describe 'layouts/_header.html.haml', :type => "view" do
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
    rendered.should contain 'Updates'
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
   
end
