# frozen_string_literal: true

require 'rails_helper'

describe LikesController do
  let(:like)     { create(:like, member:) }
  let(:member)   { create(:member)               }
  let(:blogpost) { create(:post)                 }

  before { sign_in member }

  describe "POST create" do
    before { post :create, params: { type: 'Post', id: blogpost.id, format: :json } }

    it { expect(response.content_type).to eq "application/json; charset=utf-8" }

    it { expect(Like.last.likeable_id).to eq(blogpost.id) }
    it { expect(Like.last.likeable_type).to eq('Post') }
    it { response.parsed_body["description"] == "1 like" }

    describe "Liking someone else's post" do
      it { expect(response).to have_http_status(:created) }
    end
  end

  describe "DELETE destroy" do
    before { delete :destroy, params: { type: like.likeable_type, id: like.likeable_id, format: :json } }

    it { expect(response.content_type).to eq "application/json; charset=utf-8" }

    describe "un-liking something i liked before" do
      it { expect(response).to have_http_status(:ok) }
      it { response.parsed_body["description"] == "0 likes" }
    end

    describe "Deleting someone else's like" do
      let(:like) { create(:like) }

      it { expect(response).to have_http_status(:forbidden) }
      it { response.parsed_body["error"] == "Unable to like" }
    end
  end
end
