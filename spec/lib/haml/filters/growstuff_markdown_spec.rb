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
    @crop = create(:crop)
    rendered = render_haml(haml_template(input_link(@crop.name)))
    expect(rendered).to match(/#{output_link(@crop)}/)
  end

  it "doesn't convert nonexistent crops" do
    rendered = render_haml(haml_template(input_link("not a crop")))
    expect(rendered).to match(/not a crop/)
  end

  it "doesn't convert escaped crop links" do
    @crop = create(:crop)
    rendered = render_haml(haml_template("\\" << input_link(@crop.name)))
    expect(rendered).to match(/\[#{@crop.name}\]\(crop\)/)
  end

  it "handles multiple crop links" do
    tomato = create(:tomato)
    maize = create(:maize)
    string = "#{input_link(tomato)} #{input_link(maize)}"
    rendered = render_haml(haml_template(string))
    expect(rendered).to match(/#{output_link(tomato)} #{output_link(maize)}/)
  end

  describe 'planting links' do
    subject { markdownify(text) }

    let(:planting) { create(:planting) }
    let(:url) { Rails.application.routes.url_helpers.planting_url(planting, only_path: true) }

    context 'with a planting that exists' do
      let(:text) { "See [my tomato](planting:#{planting.slug})" }

      it { is_expected.to eq "See [my tomato](#{url})" }
    end

    context 'with a planting that does not exist' do
      let(:text) { 'See [my tomato](planting:nowhere)' }

      it { is_expected.to eq 'See my tomato' }
    end

    context 'when escaped' do
      let(:text) { "\\[my tomato](planting:#{planting.slug})" }

      it { is_expected.to eq text }
    end
  end

  describe 'photos' do
    let(:photo) { create(:photo) }
    let(:text) { "Before\n\n![A jar](photo:#{photo.id}/half)\n\nAfter" }

    context 'with figures' do
      subject { markdownify(text, figures: true) }

      it { is_expected.to include %(<div class="post-figure post-figure-half">) }
      it { is_expected.to include %(<img src="#{photo.fullsize_url}" alt="A jar">) }
      it { is_expected.to include '<p class="post-figure-caption">A jar</p>' }
      it { is_expected.to include %(<a href="#{Rails.application.routes.url_helpers.photo_path(photo)}">) }
    end

    context 'with a caption containing html' do
      subject { markdownify(text.sub('A jar', 'a "b" & c'), figures: true) }

      it { is_expected.to include 'alt="a &quot;b&quot; &amp; c"' }
    end

    context 'without figures' do
      subject { markdownify(text) }

      it { is_expected.to eq "Before\n\n\n\nAfter" }
    end

    context 'when the photo does not exist' do
      subject { markdownify("![x](photo:0)", figures: true) }

      it { is_expected.to eq '' }
    end

    context 'with no size' do
      subject { markdownify("![](photo:#{photo.id})", figures: true) }

      it { is_expected.to include 'post-figure-wide' }
    end
  end

  it "converts normal markdown" do
    string = "**foo**"
    rendered = render_haml(haml_template(string))
    expect(rendered).to match(%r{<strong>foo</strong>})
  end

  it "finds crops case insensitively" do
    @crop = create(:crop, name: 'tomato', slug: 'tomato')
    rendered = render_haml(haml_template(input_link('ToMaTo')))
    expect(rendered).to match(/#{output_link(@crop, 'ToMaTo')}/)
  end

  it "fixes PT bug #78615258 (Markdown rendering bug with URLs and crops in same text)" do
    tomato = create(:tomato)
    string = "[test](http://example.com) [tomato](crop)"
    rendered = render_haml(haml_template(string))

    expect(rendered).to match(/#{output_link(tomato)}/)
    expect(rendered).to match "<a href=\"http://example.com\">test</a>"
  end

  it 'converts quick member links' do
    @member = create(:member)
    rendered = render_haml(haml_template(input_member_link(@member.login_name)))
    expect(rendered).to match(/#{output_member_link(@member)}/)
  end

  it "doesn't convert nonexistent members" do
    rendered = render_haml(haml_template(input_member_link("not a member")))
    expect(rendered).to include('not a member')
  end

  it "doesn't convert escaped members" do
    @member = create(:member)
    rendered = render_haml(haml_template("\\" << input_member_link(@member.login_name)))
    expect(rendered).to match(/\[#{@member.login_name}\]\(member\)/)
  end

  it 'converts @ member links' do
    @member = create(:member)
    rendered = render_haml(haml_template("Hey @#{@member.login_name}! What's up"))
    expect(rendered).to match(/#{output_member_link(@member, "@#{@member.login_name}")}/)
  end

  it "doesn't convert invalid @ members" do
    rendered = render_haml(haml_template("@notamember"))
    expect(rendered).to include('@notamember')
  end

  it "doesn't convert nonexistent @ members" do
    @member = create(:member)
    @member_name = @member.login_name
    @member.destroy
    rendered = render_haml(haml_template("Hey @#{@member_name}"))
    expect(rendered).to include("Hey @#{@member_name}")
  end

  it "doesn't convert escaped @ members" do
    @member = create(:member)
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
