require 'rails_helper'

describe Forum do
  let(:forum) { FactoryBot.create(:forum) }

  it "belongs to an owner" do
    forum.owner.should be_an_instance_of Member
  end

  it "stringifies nicely" do
    forum.to_s.should eq forum.name
  end

  it 'has a slug' do
    forum.slug.should eq 'permaculture'
  end

  it "has many posts" do
    @post1 = FactoryBot.create(:forum_post, forum: forum)
    @post2 = FactoryBot.create(:forum_post, forum: forum)
    forum.posts.size.should == 2
  end
end
