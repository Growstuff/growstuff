require 'spec_helper'

describe "forums/show" do
  before(:each) do
    @forum = assign(:forum, FactoryGirl.create(:forum))
    render
  end

  it "renders attributes" do
    rendered.should contain @forum.description
    rendered.should contain @forum.owner.to_s
  end
end
