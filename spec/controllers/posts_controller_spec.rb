require 'rails_helper'

describe PostsController do
  let(:member) { FactoryBot.create :member }
  shared_examples 'RSS feeds' do
    describe "RSS feed" do
      describe "returns an RSS feed" do
        before { get :index, format: "rss" }
        it { expect(response).to be_success }
        it { expect(response).to render_template("posts/index") }
        it { expect(response.content_type).to eq("application/rss+xml") }
      end
    end

    describe "GET RSS feed for individual post" do
      describe "returns an RSS feed" do
        let(:post) { FactoryBot.create :post }
        before { get :show, format: "rss", params: { id: post.slug } }
        it { expect(response).to be_success }
        it { expect(response).to render_template("posts/show") }
        it { expect(response.content_type).to eq("application/rss+xml") }
      end
    end
  end

  shared_examples 'view posts' do
    describe 'view posts' do
      let!(:post) { FactoryBot.create :post }
      let!(:post_by_member) { FactoryBot.create :post, author: member }
      describe '#index' do
        describe 'default' do
          before { get :index }
          it { expect(assigns(:posts)).to eq [post_by_member, post] }
        end
        describe 'by author' do
          before { get :index, params: { author: member.slug } }
          it { expect(assigns(:posts)).to eq [post_by_member] }
          it { expect(assigns(:author)).to eq member }
        end
      end
      describe '#show' do
        before { get :show, params: { id: post.id } }
        it { expect(assigns(:post)).to eq post }
      end
    end
  end

  context 'not logged in' do
    include_examples 'RSS feeds'
    include_examples 'view posts'
  end
  context 'logged in' do
    before(:each) do
      sign_in member
      # controller.stub(:current_member) { member }
    end

    include_examples 'RSS feeds'
    include_examples 'view posts'

    describe '#new' do
      before { get :new }
      it { expect(assigns(:post)).to be_an_instance_of Post }
    end

    describe '#create' do
      subject { post :create, params: { post: { subject: 'cool story bro', body: 'then i found $10' } } }
      it { expect { subject }.to change { Post.count }.by(1) }
      it { expect(subject.request.flash[:notice]).to_not be_nil }
    end

    describe 'modifying data' do
      let!(:post) { FactoryBot.create :post, author: member }
      describe '#edit' do
        before { get :edit, params: { id: post.id } }
        it { expect(assigns(:post)).to eq post }
      end

      describe '#update' do
        subject { put :update, params: { id: post.id, post: { subject: 'cool story bro', body: 'always blow on the pie' } } }
        it { expect { subject }.to change { post.reload; post.body }.to 'always blow on the pie' }
        it { expect(subject.request.flash[:notice]).to_not be_nil }
      end

      describe '#destroy' do
        subject { delete :destroy, params: { id: post.id } }
        it { expect { subject }.to change { Post.count }.by(-1) }
        it { expect(subject.request.flash[:notice]).to_not be_nil }
      end
    end
  end
end
