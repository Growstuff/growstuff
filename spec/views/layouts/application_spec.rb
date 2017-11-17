require 'rails_helper'

describe 'layouts/application.html.haml', type: "view" do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  it 'includes the analytics code' do
    Growstuff::Application.config.analytics_code = '<script>alert("foo!")</script>'
    render
    assert_select "script", text: 'alert("foo!")'
    rendered.should_not have_content 'script'
  end
end
