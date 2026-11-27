# frozen_string_literal: true

require 'rails_helper'

describe AnimalTag do
  let(:animal) { create(:domesticated_animal) }
  let(:mention) { "[Henrietta](animal:#{animal.id})" }

  context 'with a post mentioning an animal' do
    subject(:post) { create(:post, body: "Meet #{mention} and #{mention}") }

    it 'records each animal once' do
      expect(post.domesticated_animals).to contain_exactly(animal)
    end

    it 'links back to the post' do
      post
      expect(animal.posts).to contain_exactly(post)
    end

    it 'removes a tag when the mention is removed' do
      post.update!(body: 'No animals here')
      expect(post.domesticated_animals).to be_empty
    end

    it 'keeps the post when the animal is deleted' do
      post
      animal.destroy!
      expect(Post.find(post.id)).to eq post
    end

    it 'removes tags when the post is deleted' do
      post.destroy!
      expect(described_class.where(taggable: post)).to be_empty
    end
  end

  context 'with an escaped mention' do
    it 'does not create a tag' do
      post = create(:post, body: "\\#{mention}")
      expect(post.domesticated_animals).to be_empty
    end
  end

  context 'with a missing animal' do
    it 'does not create a tag' do
      post = create(:post, body: '[Missing](animal:0)')
      expect(post.domesticated_animals).to be_empty
    end
  end

  context 'with a comment mentioning an animal' do
    it 'records the animal' do
      comment = create(:comment, body: mention)
      expect(comment.domesticated_animals).to contain_exactly(animal)
    end
  end
end
