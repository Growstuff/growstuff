require 'spec_helper'

describe Update do
  before(:each) do
    user = User.create! :username => "test", :password => "password",
      :email => "test@example.com", :tos_agreement => true
    user.confirm!
    @id = user.id
  end

  it "should be sorted in reverse order" do
    Update.create! :subject => "first entry", :body => "blah", :user_id => @id
    Update.create! :subject => "second entry", :body => "blah", :user_id => @id
    Update.first.subject.should == "second entry"
  end

  it "should have a slug" do
    update = Update.create! :subject => "slugs are nasty",
      :body => "They leave slime everywhere", :user_id => @id
    time = update.created_at
    datestr = time.strftime("%Y%m%d")
    # 2 digit day and month, full-length years
    # Counting digits using Math.log is not precise enough!
    datestr.length.should == 4 + time.year.to_s.size
    update.slug.should == "test-#{datestr}-slugs-are-nasty"
  end
end
