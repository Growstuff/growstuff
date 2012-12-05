require 'spec_helper'

describe 'policy/tos.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should show terms of service' do
    render
    rendered.should contain 'Terms of Service'
  end
end
