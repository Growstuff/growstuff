require 'spec_helper'

describe 'about/contact.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should show support faq' do
    render
    rendered.should contain 'General contact email'
  end
end
