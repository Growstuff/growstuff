require 'spec_helper'

describe Update do
  before(:each) do
    @user = FactoryGirl.create(:user)
  end

  it "should be sorted in reverse order" do
    FactoryGirl.create(:update, :subject => 'first entry', :user => @user)
    FactoryGirl.create(:update, :subject => 'second entry', :user => @user)
    Update.first.subject.should == "second entry"
  end

  it "should have a slug" do
    @update = FactoryGirl.create(:update, :user => @user)
    @time = @update.created_at
    @datestr = @time.strftime("%Y%m%d")
    # 2 digit day and month, full-length years
    # Counting digits using Math.log is not precise enough!
    @datestr.length.should == 4 + @time.year.to_s.size
    @update.slug.should == "#{@user.username}-#{@datestr}-an-update"
  end
end
