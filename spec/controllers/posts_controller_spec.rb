# frozen_string_literal: true

require 'rails_helper'

describe PostsController do
  login_member

  def valid_attributes
    member = create(:member)
    { author_id: member.id, subject: "blah", body: "blah blah" }
  end

  describe '#new' do
    let(:crop) { create(:crop, name: 'Bush Bean') }

    it 'pre-populates the body when crop_id is present' do
      get :new, params: { crop_id: crop.slug }
      expect(assigns(:post).body).to eq("[#{crop.name}](crop)")
    end

    it 'does not pre-populate the body when crop_id is absent' do
      get :new
      expect(assigns(:post).body).to be_nil
    end
  end

  describe '#index' do
    before do
      create_list(:post, 100)
      create_list(:post, 5, author: member)
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
    describe "returns an RSS feed" do
      before { get :index, format: "rss" }

      it { expect(response).to be_successful }
      it { expect(response).to render_template("posts/index") }
      it { expect(response.content_type).to eq("application/rss+xml; charset=utf-8") }
    end
  end

  describe "GET RSS feed for individual post" do
    describe "returns an RSS feed" do
      let!(:post) { Post.create! valid_attributes }

      before { get :show, format: "rss", params: { id: post.slug } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template("posts/show") }
      it { expect(response.content_type).to eq("application/rss+xml; charset=utf-8") }
    end
  end
end
