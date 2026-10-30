# frozen_string_literal: true

require 'rails_helper'

describe "posts/show" do
  subject { rendered }

  let(:author) { create(:member, login_name: 'mary') }

  before do
    controller.stub(:current_user) { nil }
    assign(:post, post)
  end

  describe 'render post' do
    before { render }

    describe "basic post" do
      let(:post) { create(:post, author:, body: 'hello there') }

      # show the name of the member who posted the post
      it { is_expected.to have_text author.login_name }
      # Subject goes in title
      it { is_expected.to have_text('hello there') }
      # shouldn't show the subject on a single post page
      # (it appears in the title/h1 via the layout, not via this view)
      it { is_expected.to have_no_text('An Update') }
    end

    describe "should parse markdown into html" do
      let(:post) { create(:markdown_post, author:) }

      it { assert_select "strong", "strong" }
    end

    describe "shouldn't let html through in body" do
      let(:post) { create(:post, author:, body: '<a href="http://evil.com">EVIL</a>') }

      it { is_expected.to have_content('EVIL') }
      it { is_expected.to have_no_link("http://evil.com") }
    end

    describe 'script tag in post body' do
      let(:post) { create(:post, author:, body: "<script>alert('hakker!')</script>") }

      it { is_expected.to have_no_selector('script') }
    end

    describe 'script tag in post title' do
      let(:post) { create(:post, author:, subject: "<script>alert('hakker!')</script>") }

      it { is_expected.to have_no_selector('script') }
    end

    describe 'has an anchor to the comments' do
      let(:post) { create(:post, author:) }

      it { is_expected.to have_css('a[name=comments]') }
    end
  end

  context "when there is one comment" do
    let(:post) { create(:html_post, author:) }
    let!(:comment) { create(:comment, commentable: post) }

    before do
      @comments = post.comments
      render
    end

    it 'shows comment count only 1' do
      assert_select "div.post_comments", false
    end

    it "shows comments" do
      expect(subject).to have_content comment.body
    end

    it 'has an anchor to the comments' do
      assert_select 'a[name=comments]'
    end
  end

  context "when there is more than one comment" do
    let(:post) { create(:html_post, author:) }

    before do
      @comment1 = create(:comment, commentable: post, body: "F1rst!!!",
                                              created_at: Date.new(2010, 5, 17))
      @comment3 = create(:comment, commentable: post, body: "Th1rd!!!",
                                              created_at: Date.new(2012, 5, 17))
      @comment4 = create(:comment, commentable: post, body: "F0urth!!!")
      @comment2 = create(:comment, commentable: post, body: "S3c0nd!!1!",
                                              created_at: Date.new(2011, 5, 17))
      @comments = post.comments
      render
    end

    it "shows the oldest comments first" do
      expect(subject).to have_content(/#{@comment1.body}.*#{@comment2.body}.*#{@comment3.body}.*#{@comment4.body}/m)
    end
  end

  context "forum post" do
    let(:post) { create(:forum_post, author:) }

    before { render }

    it "shows forum name" do
      expect(subject).to have_content "in #{post.forum.name}"
    end
  end

  context "signed in" do
    let(:post) { create(:post, author:) }

    before do
      sign_in author
      controller.stub(:current_user) { author }
      render
    end

    it 'shows a comment button that jumps to the comment form' do
      expect(subject).to have_link "Comment", href: '#new-comment'
    end

    it 'shows the comment form on the page' do
      expect(subject).to have_css "#new-comment form[action='#{comments_path}']"
    end

    it 'renders Shareon buttons for signed in members' do
      expect(subject).to have_css '.shareon a.bluesky'
      expect(subject).to have_css '.shareon a.fediverse'
      expect(subject).to have_css '.shareon a.mastodon'
      expect(subject).to have_css '.shareon a.telegram'
      expect(subject).to have_css '.shareon a.copy-url'
      expect(subject).to have_css '.shareon a.email'
      expect(subject).to have_css '.shareon a.print'
      expect(subject).to have_css '.shareon a.web-share'
    end
  end

  context "signed out" do
    let(:post) { create(:post, author:) }

    before { render }

    it 'does not render Shareon buttons for guest users' do
      expect(subject).to have_no_css '.shareon'
    end
  end

  context 'with a card photo' do
    let(:post) { create(:post, author:) }
    let(:photo) { create(:photo, owner: author) }

    before do
      post.photos << photo
      post.update!(card_photo: photo)
      render
    end

    it 'leads the post with the photo' do
      expect(subject).to have_css ".post-card-photo img[src='#{photo.fullsize_url}']"
    end
  end

  context 'without any photo' do
    let(:post) { create(:post, author:) }

    before { render }

    it { is_expected.to have_no_css '.post-card-photo' }
  end

  context 'when the author has other posts' do
    let(:post) { create(:post, author:) }

    before do
      create(:post, author:, subject: 'Spring sowing')
      render
    end

    it 'lists them in the sidebar' do
      expect(subject).to have_css '.more-from-author', text: 'Spring sowing'
    end
  end

  context 'when the author has no other posts' do
    let(:post) { create(:post, author:) }

    before { render }

    it { is_expected.to have_no_css '.more-from-author' }
  end

  context 'with a short body' do
    let(:post) { create(:post, author:, body: 'hello there') }

    before { render }

    it { is_expected.to have_text '1 min read' }
  end
end
