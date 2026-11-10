# frozen_string_literal: true

require 'rails_helper'

describe Like do
  let(:member) { create(:member) }
  let(:post)   { create(:post)   }
  let(:photo)  { create(:photo) }

  context 'with an existing like' do
    before do
      @like = Like.create(member:, likeable: post)
    end

    it 'is valid' do
      expect(@like).to be_valid
    end

    it 'belongs to a member' do
      expect(@like.member).to be_an_instance_of Member
    end

    it 'belongs to a likeable item' do
      expect(@like).to respond_to :likeable
    end
  end

  context 'with invalid parameters' do
    it 'is invalid without a member' do
      like = Like.new
      like.likeable = post
      expect(like).not_to be_valid
    end

    it 'is invalid without a likeable item' do
      like = Like.new
      like.member = member
      expect(like).not_to be_valid
    end
  end

  it 'does not allow duplicate likes by the same member' do
    Like.create(member:, likeable: post)
    second_like = Like.new(member:, likeable: post)
    expect(second_like).not_to be_valid
  end

  it 'destroys like if post no longer exists' do
    like = Like.create(member:, likeable: post)
    post.destroy
    expect(Like.all).not_to include like
  end

  it 'destroys like if member no longer exists' do
    like = Like.create(member:, likeable: post)
    member.destroy
    expect(Like.all).not_to include like
  end

  context "when the likeable author has blocked the member" do
    let(:likeable_author) { create(:member) }
    let(:post_author) { create(:member) }
    let(:post) { create(:post, author: likeable_author) }

    before do
      likeable_author.blocks.create(blocked: member)
    end

    it "is not valid" do
      like = build(:like, likeable: post, member: member)
      expect(like).not_to be_valid
    end
  end

  { 'a post' => :post, 'a photo' => :photo }.each do |name, thing|
    describe "liking #{name}" do
      subject(:likeable) { send(thing) }

      context 'before it is liked' do
        it('is not liked by the member') { expect(likeable.liked_by?(member)).to be false }
        it('is not liked by no member') { expect(likeable.liked_by?(nil)).to be false }
        it('has no names of members who like it') { expect(likeable.liked_by_members_names).to eq [] }
      end

      context 'after the member likes it' do
        before { Like.create(member:, likeable:) }

        it('is liked by the member') { expect(likeable.liked_by?(member)).to be true }
        it('names the member') { expect(likeable.liked_by_members_names).to eq [member.login_name] }
      end
    end
  end
end
