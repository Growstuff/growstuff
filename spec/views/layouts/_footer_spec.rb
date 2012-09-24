require 'spec_helper'

describe 'layouts/_footer.html.haml', :type => "view" do
    
    before(:each) do
      render
    end

    it 'should have links in footer' do
        rendered.should contain 'About'
        rendered.should contain 'License'
        rendered.should contain 'Github'
        rendered.should contain 'Mailing list'
        rendered.should contain 'Community Guidelines'
    end
end
