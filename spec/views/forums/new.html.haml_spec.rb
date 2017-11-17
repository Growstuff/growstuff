require 'rails_helper'

describe "forums/new" do
  before(:each) do
    @forum = assign(:forum, FactoryBot.create(:forum))
    render
  end

  it "renders new forum form" do
    assert_select "form", action: forums_path, method: "post" do
      assert_select "input#forum_name", name: "forum[name]"
      assert_select "textarea#forum_description", name: "forum[description]"
      assert_select "select#forum_owner_id", name: "forum[owner_id]"
    end
  end
end
