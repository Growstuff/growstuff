require 'rails_helper'

describe 'members/show.rss.haml', type: "view" do
  subject { rendered }

  before(:each) do
    @member = assign(:member, FactoryBot.create(:member, login_name: 'callum'))
    @post1 = FactoryBot.create(:post, id: 1, author: @member)
    @post2 = FactoryBot.create(:markdown_post, id: 2, author: @member)
    assign(:posts, [@post1, @post2])
    render
  end

  it 'shows RSS feed title' do
    is_expected.to have_text("callum's recent posts")
  end

  it 'shows content of posts' do
    is_expected.to have_content "This is some text."
  end

  it 'renders post bodies to HTML and XML-escapes them' do
    # The variable "rendered" has been entity-replaced and tag-stripped
    # The literal string output contains "&lt;strong&gt;" etc.
    is_expected.to have_content "<strong>strong</strong>"
  end

  it 'gives the author in the item title' do
    is_expected.to have_content "#{@post1.subject} by #{@post1.author}"
  end
end
