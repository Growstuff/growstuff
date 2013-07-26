require 'spec_helper'

describe 'layouts/application.html.haml', :type => "view" do
  before(:each) do
    controller.stub(:current_user) { nil }
    render
  end

  it 'includes the analytics code' do
    Growstuff::Application.config.analytics_code = '<script>alert("foo!")</script>'
    assert_select "script", :text => 'alert("foo!")'
    rendered.should_not contain 'script'
  end

end
