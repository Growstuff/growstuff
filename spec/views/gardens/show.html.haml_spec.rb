require 'spec_helper'

describe "gardens/show" do
  before(:each) do
    @user = User.create(
        :username => 'foo',
        :email => 'foo@example.com',
        :password => 'irrelevant',
        :tos_agreement => true
    )
    @user.confirm!
    @garden = assign(:garden, stub_model(Garden,
      :name => "Garden Name",
      :user_id => @user.id
    ))
  end

  context 'logged out' do
    it 'should not show the edit button' do
      render
      rendered.should_not contain 'Edit'
    end
  end

  context 'signed in' do
    it 'should have an edit button' do
      sign_in @user
      render
      rendered.should contain 'Edit'
    end
  end

end
