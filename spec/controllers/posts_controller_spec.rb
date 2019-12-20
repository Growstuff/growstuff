# frozen_string_literal: true

require 'rails_helper'

describe PostsController do
  login_member

  def valid_attributes
    member = FactoryBot.create(:member)
    { author_id: member.id, subject: "blah", body: "blah blah" }
  end

  describe '#index' do
    before do
      FactoryBot.create_list :post, 100
      FactoryBot.create_list :post, 5, author: member
    end
    describe "everyone's posts" do
      before { get :index }
      it { expect(assigns(:posts).size).to eq 12 }
    end
    describe "one member's posts" do
      before { get :index, params: { member_slug: member.slug } }
      it { expect(assigns(:posts).size).to eq 5 }
      it { expect(assigns(:posts).first.author).to eq member }
    end
  end

  describe "GET RSS feed" do
    it "returns an RSS feed" do
      get :index, format: "rss"
      expect(response).to be_successful
      expect(response).to render_template("posts/index")
      expect(response.content_type).to eq("application/rss+xml")
    end
  end

  describe "GET RSS feed for individual post" do
    it "returns an RSS feed" do
      post = Post.create! valid_attributes
      get :show, format: "rss", params: { id: post.slug }
      expect(response).to be_successful
      expect(response).to render_template("posts/show")
      expect(response.content_type).to eq("application/rss+xml")
    end
  end
end
