require 'spec_helper'

describe 'policy/community.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should show community guidelines' do
    render
    rendered.should contain 'Growstuff is a community by and for food-gardeners.'
  end
end
