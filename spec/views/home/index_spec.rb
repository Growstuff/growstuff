require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do

  it 'should have description' do
    render
    rendered.should contain 'Growstuff is a community of food gardeners'
    rendered.should contain 'We welcome you regardless of your experience, and invite you to be part of our development process.'
  end
end
