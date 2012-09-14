describe 'devise/mailer/unlock_instructions.html.haml', :type => "view" do
  context "logged in" do
    before(:each) do
      @resource = mock_model(User)
      @resource.should_receive(:email).and_return("example@example.com")
      @resource.should_receive(:unlock_token).and_return("fred")
      render
    end

    it "should explain what's happened" do
      rendered.should contain "Your account has been locked"
    end

    it "should have an unlock link" do
      rendered.should contain "Unlock my account"
    end
  end
end

