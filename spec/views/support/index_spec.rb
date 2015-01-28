require 'rails_helper'

describe 'support/index.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should show support faq' do
    rendered.should have_content 'About Growstuff'
  end

  it 'should not mention Courtney any more' do
    rendered.should_not have_content 'Courtney'
    rendered.should_not have_content 'phazel'
  end
end
