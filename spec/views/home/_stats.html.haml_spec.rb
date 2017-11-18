require 'rails_helper'

describe 'home/_stats.html.haml', type: "view" do
  it 'has activity stats' do
    render
    rendered.should have_content "So far, 0 members have planted 0 crops"
  end
end
