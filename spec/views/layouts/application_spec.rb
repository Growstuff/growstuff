require 'spec_helper'

describe 'layouts/application.html.haml', :type => "view" do
    it 'should have links in footer' do
        render
        rendered.should contain 'About'
    end
end
