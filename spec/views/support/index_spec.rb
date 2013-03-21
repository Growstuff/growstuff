require 'spec_helper'

describe 'support/index.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should show support faq' do
    render
    rendered.should contain 'About Growstuff'
  end
end
