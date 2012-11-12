require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  before(:each) do
    assign(:crops, [
      stub_model(Crop,
        :system_name => "Maize",
        :en_wikipedia_url => "http://en.wikipedia.org/wiki/Maize"
      ),
      stub_model(Crop,
        :system_name => "Tomato",
        :en_wikipedia_url => "http://en.wikipedia.org/wiki/Tomato"
      )
    ])
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
     rendered.should contain '(0)'
  end
  

  it 'should have description' do
    render
    rendered.should contain 'Growstuff is a community of food gardeners'
    rendered.should contain 'We welcome you regardless of your experience, and invite you to be part of our development process.'
  end
end
