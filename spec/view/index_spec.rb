require 'spec_helper'

describe 'home/index.html.erb', :type => "view" do
  context "when not logged in" do

    before(:each) do
      view.stub(:user_signed_in).and_return(false)
      view.stub(:current_user).and_return(nil)
    end

    it 'shows the homepage' do
        render
        rendered.should contain 'Growstuff'
    end
    
  end
end
