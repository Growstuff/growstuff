require 'rails_helper'

describe Forum do

  let(:forum) { FactoryGirl.create(:forum) }

  it "belongs to an owner" do
    forum.owner.should be_an_instance_of Member
  end

  it "stringifies nicely" do
    "#{forum}".should eq forum.name
  end

  it 'has a slug' do
    forum.slug.should eq 'permaculture'
  end

  it "has many posts" do
    @post1 = FactoryGirl.create(:forum_post, forum: forum)
    @post2 = FactoryGirl.create(:forum_post, forum: forum)
    forum.posts.size.should == 2
  end

  it "orders posts in reverse chron order" do
    @post1 = FactoryGirl.create(:forum_post, forum: forum, created_at: 2.days.ago)
    @post2 = FactoryGirl.create(:forum_post, forum: forum, created_at: 1.day.ago)
    forum.posts.first.should eq @post2
  end

end
