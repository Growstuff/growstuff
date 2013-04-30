require 'spec_helper'

describe 'support/index.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should show support faq' do
    rendered.should contain 'About Growstuff'
  end

  it 'should not mention Courtney any more' do
    rendered.should_not contain 'Courtney'
    rendered.should_not contain 'phazel'
  end
end
