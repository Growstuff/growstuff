# frozen_string_literal: true

require 'rails_helper'

describe LikesController do
  let(:like)     { FactoryBot.create :like, member: member  }
  let(:member)   { FactoryBot.create(:member)               }
  let(:blogpost) { FactoryBot.create(:post)                 }

  before { sign_in member }

  describe "POST create" do
    before { post :create, params: { type: 'Post', id: blogpost.id, format: :json } }

    it { expect(response.content_type).to eq "application/json" }

    it { expect(Like.last.likeable_id).to eq(blogpost.id) }
    it { expect(Like.last.likeable_type).to eq('Post') }
    it { JSON.parse(response.body)["description"] == "1 like" }

    describe "Liking someone else's post" do
      it { expect(response.code).to eq('201') }
    end

    describe "Liking your own post" do
    end
  end

  describe "DELETE destroy" do
    before { delete :destroy, params: { type: like.likeable_type, id: like.likeable_id, format: :json } }

    it { expect(response.content_type).to eq "application/json" }

    describe "un-liking something i liked before" do
      it { expect(response.code).to eq('200') }
      it { JSON.parse(response.body)["description"] == "0 likes" }
    end

    describe "Deleting someone else's like" do
      let(:like) { FactoryBot.create :like }

      it { expect(response.code).to eq('403') }
      it { JSON.parse(response.body)["error"] == "Unable to like" }
    end
  end
end
