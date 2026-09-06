# frozen_string_literal: true

require 'rails_helper'

describe Forum do
  let(:forum) { create(:forum) }

  it "belongs to an owner" do
    expect(forum.owner).to be_an_instance_of Member
  end

  it "stringifies nicely" do
    expect(forum.to_s).to eq forum.name
  end

  it 'has a slug' do
    expect(forum.slug).to eq 'permaculture'
  end

  it "has many posts" do
    @post1 = create(:forum_post, forum:)
    @post2 = create(:forum_post, forum:)
    expect(forum.posts.size).to eq 2
  end
end
