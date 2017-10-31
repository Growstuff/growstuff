require 'rails_helper'

describe 'like' do
  let(:member) { FactoryBot.create(:member) }
  let(:post) { FactoryBot.create(:post) }

  context 'existing like' do
    before(:each) do
      @like = Like.create(member: member, likeable: post)
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

  context 'invalid parameters' do
    it 'is invalid without a member' do
      like = Like.new
      like.likeable = post
      expect(like).to_not be_valid
    end

    it 'is invalid without a likeable item' do
      like = Like.new
      like.member = member
      expect(like).to_not be_valid
    end
  end

  it 'does not allow duplicate likes by the same member' do
    Like.create(member: member, likeable: post)
    second_like = Like.new(member: member, likeable: post)
    expect(second_like).to_not be_valid
  end

  it 'destroys like if post no longer exists' do
    like = Like.create(member: member, likeable: post)
    post.destroy
    expect(Like.all).to_not include like
  end

  it 'destroys like if member no longer exists' do
    like = Like.create(member: member, likeable: post)
    member.destroy
    expect(Like.all).to_not include like
  end
end
