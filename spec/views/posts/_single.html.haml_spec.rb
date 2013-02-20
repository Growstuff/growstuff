require 'spec_helper'

describe "posts/_single" do
  before(:each) do
    @post = FactoryGirl.create(:post)
  end

  context "0 comments" do
    before(:each) do
      render :partial => "single", :locals => {
        :post => @post
      }
    end

    it "renders the number of comments" do
      rendered.should contain "0 comments"
    end
  end

  context "1 comment" do
    before(:each) do
      @comment = FactoryGirl.create(:comment, :post => @post)
      render :partial => "single", :locals => {
        :post => @post
      }
    end

    it "renders the number of comments" do
      rendered.should contain "1 comment"
    end

    it "contains a link to post" do
      assert_select "a[href=#{post_path @post}]"
    end

    it "contains link to new comment" do
      assert_select "a[href=#{new_comment_path(:post_id => @post.id)}]", "Comment"
    end
  end

  context "2 comments" do
    before(:each) do
      @comment = FactoryGirl.create(:comment, :post => @post)
      @comment2 = FactoryGirl.create(:comment, :post => @post)
      render :partial => "single", :locals => {
        :post => @post
      }
    end

    it "renders the number of comments" do
      rendered.should contain "2 comments"
    end
  end

  context "hide comment" do
    before(:each) do
      @comment = FactoryGirl.create(:comment, :post => @post)
      render :partial => "single", :locals => {
        :post => @post, :hide_comments => true
      }
    end

    it "renders no value of comments" do
      rendered.should_not contain "1 comment"
    end

    it "does not contain link to post" do
      assert_select "a[href=#{post_path @post}]", false
    end

    it "does not contain link to new comment" do
      assert_select "a[href=#{new_comment_path(:post_id => @post.id)}]", false
    end

  end
end



 