# frozen_string_literal: true

require 'rails_helper'

describe 'members/show.rss.haml', type: "view" do
  subject { rendered }

  before do
    @member = assign(:member, FactoryBot.create(:member, login_name: 'callum'))
    @post1 = FactoryBot.create(:post, id: 1, author: @member, body: "This is some text.")
    @post2 = FactoryBot.create(:markdown_post, id: 2, author: @member)
    assign(:posts, [@post1, @post2])
    render
  end

  it 'shows RSS feed title' do
    expect(subject).to have_text("callum's recent posts")
  end

  it 'shows content of posts' do
    expect(subject).to have_content "This is some text."
  end

  it 'renders post bodies to HTML and XML-escapes them' do
    # The variable "rendered" has been entity-replaced and tag-stripped
    # The literal string output contains "&lt;strong&gt;" etc.
    expect(subject).to have_content "<strong>strong</strong>"
  end

  it 'gives the author in the item title' do
    expect(subject).to have_content "#{@post1.subject} by #{@post1.author}"
  end
end
