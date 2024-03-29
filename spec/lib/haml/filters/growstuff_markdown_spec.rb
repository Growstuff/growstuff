require 'rails_helper'
require 'haml/filters'
require 'haml/filters/growstuff_markdown'

def input_link(name)
  "[#{name}](crop)"
end

def output_link(crop, name = nil)
  url = Rails.application.routes.url_helpers.crop_url(crop, only_path: true)
  return "<a href=\"#{url}\">#{name}</a>" if name

  "<a href=\"#{url}\">#{crop.name}</a>"
end

def input_member_link(name)
  "[#{name}](member)"
end

def output_member_link(member, name = nil)
  url = Rails.application.routes.url_helpers.member_url(member, only_path: true)
  return "<a href=\"#{url}\">#{name}</a>" if name

  "<a href=\"#{url}\">#{member.login_name}</a>"
end

describe 'Haml::Filters::Growstuff_Markdown' do
  include ApplicationHelper

  it 'converts quick crop links' do
    @crop = FactoryBot.create(:crop)
    rendered = render_haml(haml_template(input_link(@crop.name)))
    expect(rendered).to match(/#{output_link(@crop)}/)
  end

  it "doesn't convert nonexistent crops" do
    rendered = render_haml(haml_template(input_link("not a crop")))
    expect(rendered).to match(/not a crop/)
  end

  it "doesn't convert escaped crop links" do
    @crop = FactoryBot.create(:crop)
    rendered = render_haml(haml_template("\\" << input_link(@crop.name)))
    expect(rendered).to match(/\[#{@crop.name}\]\(crop\)/)
  end

  it "handles multiple crop links" do
    tomato = FactoryBot.create(:tomato)
    maize = FactoryBot.create(:maize)
    string = "#{input_link(tomato)} #{input_link(maize)}"
    rendered = render_haml(haml_template(string))
    expect(rendered).to match(/#{output_link(tomato)} #{output_link(maize)}/)
  end

  it "converts normal markdown" do
    string = "**foo**"
    rendered = render_haml(haml_template(string))
    expect(rendered).to match(%r{<strong>foo</strong>})
  end

  it "finds crops case insensitively" do
    @crop = FactoryBot.create(:crop, name: 'tomato', slug: 'tomato')
    rendered = render_haml(haml_template(input_link('ToMaTo')))
    expect(rendered).to match(/#{output_link(@crop, 'ToMaTo')}/)
  end

  it "fixes PT bug #78615258 (Markdown rendering bug with URLs and crops in same text)" do
    tomato = FactoryBot.create(:tomato)
    string = "[test](http://example.com) [tomato](crop)"
    rendered = render_haml(haml_template(string))

    expect(rendered).to match(/#{output_link(tomato)}/)
    expect(rendered).to match "<a href=\"http://example.com\">test</a>"
  end

  it 'converts quick member links' do
    @member = FactoryBot.create(:member)
    rendered = render_haml(haml_template(input_member_link(@member.login_name)))
    expect(rendered).to match(/#{output_member_link(@member)}/)
  end

  it "doesn't convert nonexistent members" do
    rendered = render_haml(haml_template(input_member_link("not a member")))
    expect(rendered).to include('not a member')
  end

  it "doesn't convert escaped members" do
    @member = FactoryBot.create(:member)
    rendered = render_haml(haml_template("\\" << input_member_link(@member.login_name)))
    expect(rendered).to match(/\[#{@member.login_name}\]\(member\)/)
  end

  it 'converts @ member links' do
    @member = FactoryBot.create(:member)
    rendered = render_haml(haml_template("Hey @#{@member.login_name}! What's up"))
    expect(rendered).to match(/#{output_member_link(@member, "@#{@member.login_name}")}/)
  end

  it "doesn't convert invalid @ members" do
    rendered = render_haml(haml_template("@notamember"))
    expect(rendered).to include('@notamember')
  end

  it "doesn't convert nonexistent @ members" do
    @member = FactoryBot.create(:member)
    @member_name = @member.login_name
    @member.destroy
    rendered = render_haml(haml_template("Hey @#{@member_name}"))
    expect(rendered).to include("Hey @#{@member_name}")
  end

  it "doesn't convert escaped @ members" do
    @member = FactoryBot.create(:member)
    rendered = render_haml(haml_template("Hey \\@#{@member.login_name}! What's up"))
    expect(rendered).to include("Hey @#{@member.login_name}!")
  end

  def haml_template(input)
    <<~HTML
      :markdown
        #{markdownify input}
    HTML
  end

  def render_haml(haml)
    locals = {}
    options = {}
    Haml::Template.new(options) { haml }.render(Object.new, locals)
  end
end
