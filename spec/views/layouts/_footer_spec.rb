require 'spec_helper'

describe 'layouts/_footer.html.haml', :type => "view" do
    
    before(:each) do
      render
    end

    it 'should have links in footer' do
        rendered.should contain 'About'
        assert_select("a[href=#{'/policy/tos'}]", 'Terms of Service')
        assert_select("a[href=#{'/policy/community'}]", 'Community Guidelines')
        rendered.should contain 'License'
        rendered.should contain 'Github'
        rendered.should contain 'Mailing list'
    end

    it 'should not have an explicit wiki link' do
        rendered.should_not contain 'Wiki'
    end
end
