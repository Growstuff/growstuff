# frozen_string_literal: true

require 'rails_helper'

describe "Posts" do
  describe "GET /posts" do
    it "works! (now write some real specs)" do
      get posts_path
      response.status.should be(200)
    end
  end

  describe 'PATCH /posts/:id with a card photo' do
    subject(:request) { patch post_path(post, format: :json), params: { post: { card_photo_id: photo.id } } }

    let(:member) { create(:member) }
    let(:post) { create(:post, author: member) }
    let(:photo) { create(:photo, owner: member) }

    before do
      post.photos << photo
      sign_in member
    end

    it 'sets the card photo' do
      request
      expect(post.reload.card_photo).to eq photo
    end

    context 'when the photo is not in the post' do
      let(:photo) { create(:photo, owner: member) }

      before { post.photos.destroy_all }

      it 'is rejected' do
        request
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe 'drafts' do
    let(:member) { create(:member) }
    let!(:draft) { create(:post, author: member, draft: true) }

    context 'when signed in as the author' do
      before { sign_in member }

      it 'shows the draft' do
        get post_path(draft)
        expect(response).to have_http_status :ok
      end

      it 'lists the draft on their own page' do
        get member_posts_path(member_slug: member.slug)
        expect(response.body).to include draft.subject
      end

      it 'lists the draft under their drafts' do
        get member_posts_path(member_slug: member.slug, drafts: 1)
        expect(response.body).to include draft.subject
      end

      it 'leaves published posts out of their drafts' do
        published = create(:post, author: member)
        get member_posts_path(member_slug: member.slug, drafts: 1)
        expect(response.body).not_to include published.subject
      end

      it 'links to their drafts from the sidebar' do
        get member_posts_path(member_slug: member.slug)
        expect(response.body).to include 'My drafts'
      end

      it 'publishes the draft' do
        patch post_path(draft), params: { post: { draft: 'false' } }
        expect(draft.reload).to be_published
      end

      it 'keeps the draft a draft when saved as one' do
        patch post_path(draft), params: { post: { subject: 'Still drafting', draft: 'true' } }
        expect(draft.reload).to be_draft
      end

      it 'creates a draft from an autosave' do
        post posts_path(format: :json), params: { post: { subject: 'Auto', body: 'saved', draft: true } }
        expect(Post.with_drafts.find_by(subject: 'Auto')).to be_draft
      end
    end

    context 'when signed in as someone else' do
      before { sign_in create(:member) }

      it 'does not show the draft' do
        get post_path(draft)
        expect(response).to have_http_status :not_found
      end

      it 'does not list the draft on the author page' do
        get member_posts_path(member_slug: member.slug)
        expect(response.body).not_to include draft.subject
      end
    end

    context 'when signed out' do
      it 'does not list the draft' do
        get posts_path
        expect(response.body).not_to include draft.subject
      end
    end
  end

  describe 'POST /posts/preview' do
    before { sign_in create(:member) }

    it 'renders the markdown' do
      post preview_posts_path, params: { body: '**bold**' }, as: :json
      expect(response.body).to include '<strong>bold</strong>'
    end

    it 'strips scripts' do
      post preview_posts_path, params: { body: '<script>alert(1)</script>' }, as: :json
      expect(response.body).not_to include '<script'
    end
  end

  describe 'GET /posts/link_suggestions' do
    subject(:json) { response.parsed_body }

    let(:member) { create(:member) }
    let!(:friend) { create(:member, login_name: 'pumpkinfan') }
    let(:crop) { create(:crop, name: 'pumpkin') }
    let!(:mine) { create(:planting, owner: member, crop:) }

    before do
      create(:planting, crop:) # someone else's
      sign_in member
      get link_suggestions_posts_path(format: :json), params: { term: 'pump' }
    end

    it 'finds members by login name' do
      expect(json['members']).to eq [{ 'name' => 'pumpkinfan' }]
    end

    it 'finds only the writers own plantings' do
      expect(json['plantings'].pluck('slug')).to eq [mine.slug]
    end

    context 'without a term' do
      before { get link_suggestions_posts_path(format: :json) }

      it { expect(json).to eq('members' => [], 'plantings' => []) }
    end
  end
end
