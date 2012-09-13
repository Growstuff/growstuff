describe 'devise/confirmations/new.html.haml', :type => "view" do

  before(:each) do
    @view.stub(:resource).and_return(User.new)
    @view.stub(:resource_name).and_return("user")
    @view.stub(:resource_class).and_return(User)
    @view.stub(:devise_mapping).and_return(Devise.mappings[:user])
    render
  end

  it 'should have a Resend button' do
    rendered.should contain "Resend confirmation instructions"
  end
end
