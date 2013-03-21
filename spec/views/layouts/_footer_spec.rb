require 'spec_helper'

describe 'layouts/_footer.html.haml', :type => "view" do

    before(:each) do
      render
    end

    it 'should have links in footer' do
        rendered.should contain 'About'
        assert_select("a[href=/policy/tos]", 'Terms of Service')
        assert_select("a[href=/policy/privacy]", 'Privacy Policy')
        assert_select("a[href=/policy/community]", 'Community Guidelines')
        rendered.should contain 'Open Source'
        assert_select("a[href=/support]", 'Support/FAQ')
    end

    it 'should not have an explicit wiki link' do
        rendered.should_not contain 'Wiki'
    end
end
