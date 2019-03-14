# frozen_string_literal: true

describe 'devise/confirmations/new.html.haml', type: "view" do
  before do
    @view.stub(:resource).and_return(Member.new)
    @view.stub(:resource_name).and_return("member")
    @view.stub(:resource_class).and_return(Member)
    @view.stub(:devise_mapping).and_return(Devise.mappings[:member])
    render
  end

  it 'contains a login field' do
    rendered.should have_content "Enter either your login name or your email address"
  end
end
