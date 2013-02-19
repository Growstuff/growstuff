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

end



 