require 'spec_helper'

describe "updates/show" do
  before(:each) do
    @user = User.create!(
      :username => "test_user",
      :email => "test@example.com",
      :password => "password",
      :tos_agreement => true
    )
  end

  it "renders the post" do
    @update = assign(:update, stub_model(Update,
      :user_id => @user.id,
      :subject => "Subject",
      :body => "MyText"
    ))
    render
    rendered.should match(/test_user/)
    # Subject goes in title
    rendered.should match(/MyText/)
  end

  it "should parse markdown into html" do
    @update = assign(:update, stub_model(Update,
      :user_id => @user.id,
      :subject => "Subject",
      :body => "**strong**"
    ))
    render
    rendered.should match(/<strong>strong<\/strong>/)
  end

  it "shouldn't let html through in body" do
    @update = assign(:update, stub_model(Update,
      :user_id => @user.id,
      :subject => "<b>Subject<b>",
      :body => '<a href="http://evil.com">EVIL</a>'
    ))
    render
    rendered.should match(/EVIL/)
    rendered.should_not match(/a href="http:\/\/evil.com"/)
  end

  it "shouldn't show the subject on the single update page" do
    @update = assign(:update, stub_model(Update,
      :user_id => @user.id,
      :subject => "<b>Subject<b>",
      :body => '<a href="http://evil.com">EVIL</a>'
    ))
    render
    rendered.should_not match(/Subject/)
  end

end
