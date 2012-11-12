require 'spec_helper'

describe Update do
  it "should be sorted in reverse order" do
    Update.create! :subject => "first entry", :body => "blah", :user_id => 1
    Update.create! :subject => "second entry", :body => "blah", :user_id => 1
    Update.first.subject.should == "second entry"
  end
end
