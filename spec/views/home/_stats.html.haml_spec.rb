require 'spec_helper'

describe 'home/_stats.html.haml', :type => "view" do
  it 'has activity stats' do
    render
    rendered.should contain "So far, 0 members have planted 0 crops"
  end
end
