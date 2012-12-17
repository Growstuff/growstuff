require 'spec_helper'

describe "members/index" do
  before(:each) do
    assign(:members, [
      User.create!(
        :username => "Marmaduke Blundell-Hollinshead-Blundell-Tolemache-Plantagenet-Whistlebinkie, 3rd Duke of Marmoset",
        :password => "ilikehorses",
        :email => "binky@example.com",
        :tos_agreement => true
      ),
      User.create!(
        :username => "bob",
        :password => "password",
        :email => "bob@example.com",
        :tos_agreement => true
      )
    ])
    render
  end

  it "truncates long names" do
    rendered.should contain "marmaduke blundell-hollinsh..."
  end

  it "does not truncate short names" do
    rendered.should contain "bob"
    rendered.should_not contain "bob..."
  end
  
  it "counts the number of members" do
    rendered.should contain "Displaying 2 members"
  end

  it "contains two gravatar icons" do
    assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
  end
  
end
