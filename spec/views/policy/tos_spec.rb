require 'rails_helper'

describe 'policy/tos.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should show terms of service' do
    render
    rendered.should have_content 'Terms of Service'
  end
end
