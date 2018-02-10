require 'rails_helper'

describe "comments/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @comment = assign(:comment, FactoryBot.create(:comment))
    render
  end

  it "renders the comment" do
    rendered.should have_content @comment.author.login_name
    rendered.should have_content @comment.body
  end
end
