require 'spec_helper'

describe 'members/show.rss.haml', :type => "view" do
  before(:each) do
    @member = assign(:member, FactoryGirl.create(:member))
    assign(:posts, [
      FactoryGirl.build(:post, :id => 1, :author => @member),
      FactoryGirl.build(:markdown_post, :id => 2, :author => @member)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain /member\d+'s recent posts/
  end

  it 'shows content of posts' do
    rendered.should contain "This is some text."
  end

  it 'renders post bodies to HTML and XML-escapes them' do
# The variable "rendered" has been entity-replaced and tag-stripped
# The literal string output contains "&lt;strong&gt;" etc.
    rendered.should contain "<strong>strong</strong>"
  end

end
