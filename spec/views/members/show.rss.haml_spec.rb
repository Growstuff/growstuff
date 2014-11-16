require 'rails_helper'

describe 'members/show.rss.haml', :type => "view" do
  before(:each) do
    @member = assign(:member, FactoryGirl.create(:member))
    @post1 = FactoryGirl.create(:post, :id => 1, :author => @member)
    @post2 = FactoryGirl.create(:markdown_post, :id => 2, :author => @member)
    assign(:posts, [@post1, @post2])
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content /member\d+'s recent posts/
  end

  it 'shows content of posts' do
    rendered.should have_content "This is some text."
  end

  it 'renders post bodies to HTML and XML-escapes them' do
# The variable "rendered" has been entity-replaced and tag-stripped
# The literal string output contains "&lt;strong&gt;" etc.
    rendered.should have_content "<strong>strong</strong>"
  end

  it 'gives the author in the item title' do
    rendered.should have_content "#{@post1.subject} by #{@post1.author}"
  end

end
