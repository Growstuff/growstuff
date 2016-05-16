require 'rails_helper'
require 'haml/filters'
require 'haml/filters/growstuff_markdown'

def input_link(name)
  return "[#{name}](crop)"
end

def output_link(crop, name=nil)
  url = Rails.application.routes.url_helpers.crop_url(crop, :host => Growstuff::Application.config.host)
  if name
    return "<a href=\"#{url}\">#{name}</a>"
  else
    return "<a href=\"#{url}\">#{crop.name}</a>"
  end
end

def input_member_link(name)
  return "[#{name}](member)"
end

def output_member_link(member, name=nil)
  url = Rails.application.routes.url_helpers.member_url(member, :only_path => true)
  if name
    return "<a href=\"#{url}\">#{name}</a>"
  else
    return "<a href=\"#{url}\">#{member.login_name}</a>"
  end
end


describe 'Haml::Filters::Growstuff_Markdown' do
   it 'is registered as the handler for :growstuff_markdown' do
     Haml::Filters::defined['growstuff_markdown'].should ==
       Haml::Filters::GrowstuffMarkdown
   end

  it 'converts quick crop links' do
    @crop = FactoryGirl.create(:crop)
    rendered = Haml::Filters::GrowstuffMarkdown.render(input_link(@crop.name))
    rendered.should match /#{output_link(@crop)}/
  end

  it "doesn't convert nonexistent crops" do
    rendered = Haml::Filters::GrowstuffMarkdown.render(input_link("not a crop"))
    rendered.should match /not a crop/
  end

  it "doesn't convert escaped crop links" do
    @crop = FactoryGirl.create(:crop)
    rendered = Haml::Filters::GrowstuffMarkdown.render( "\\" << input_link(@crop.name))
    rendered.should match /\[#{@crop.name}\]\(crop\)/
  end

  it "handles multiple crop links" do
    tomato = FactoryGirl.create(:tomato)
    maize = FactoryGirl.create(:maize)
    string = "#{input_link(tomato)} #{input_link(maize)}"
    rendered = Haml::Filters::GrowstuffMarkdown.render(string)
    rendered.should match /#{output_link(tomato)} #{output_link(maize)}/
  end

  it "converts normal markdown" do
    string = "**foo**"
    rendered = Haml::Filters::GrowstuffMarkdown.render(string)
    rendered.should match /<strong>foo<\/strong>/
  end

  it "finds crops case insensitively" do
    @crop = FactoryGirl.create(:crop, :name => 'tomato')
    rendered = Haml::Filters::GrowstuffMarkdown.render(input_link('ToMaTo'))
    rendered.should match /#{output_link(@crop, 'ToMaTo')}/
  end

  it "fixes PT bug #78615258 (Markdown rendering bug with URLs and crops in same text)" do
    tomato = FactoryGirl.create(:tomato)
    string = "[test](http://example.com) [tomato](crop)"
    rendered = Haml::Filters::GrowstuffMarkdown.render(string)
    rendered.should match /#{output_link(tomato)}/
    rendered.should match "<a href=\"http://example.com\">test</a>"
  end

  it 'converts quick member links' do
    @member = FactoryGirl.create(:member)
    rendered = Haml::Filters::GrowstuffMarkdown.render(input_member_link(@member.login_name))
    rendered.should match /#{output_member_link(@member)}/
  end

  it "doesn't convert nonexistent members" do
    rendered = Haml::Filters::GrowstuffMarkdown.render(input_member_link("not a member"))
    rendered.should match /not a member/
  end

  it "doesn't convert escaped members" do
    @member = FactoryGirl.create(:member)
    rendered = Haml::Filters::GrowstuffMarkdown.render("\\" << input_member_link(@member.login_name))
    rendered.should match /\[#{@member.login_name}\]\(member\)/
  end


  it 'converts @ member links' do
    @member = FactoryGirl.create(:member)
    rendered = Haml::Filters::GrowstuffMarkdown.render("Hey @#{@member.login_name}! What's up")
    rendered.should match /#{output_member_link(@member, "@#{@member.login_name}")}/
  end

  it "doesn't convert invalid @ members" do
    rendered = Haml::Filters::GrowstuffMarkdown.render("@not-a-member")
    rendered.should match /@not-a-member/
  end

  it "doesn't convert nonexistent @ members" do
    @member = FactoryGirl.create(:member)
    @member_name = @member.login_name
    @member.destroy
    rendered = Haml::Filters::GrowstuffMarkdown.render("Hey @#{@member_name}")
    rendered.should match /Hey @#{@member_name}/
  end

  it "doesn't convert escaped @ members" do
    @member = FactoryGirl.create(:member)
    rendered = Haml::Filters::GrowstuffMarkdown.render("Hey \\@#{@member.login_name}! What's up")
    rendered.should match /Hey @#{@member.login_name}!/
  end

end
