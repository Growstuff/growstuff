require 'rails_helper'

describe "comments/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @comment = assign(:comment, FactoryGirl.create(:comment))
    render
  end

  it "renders the comment" do
    rendered.should contain @comment.author.login_name
    rendered.should contain @comment.body
  end
end
