require 'spec_helper'
require 'haml/filters'
require 'haml/filters/growstuff_markdown'

def input_link(name)
  return "[#{name}](crop)"
end

def output_link(crop)
  url = Rails.application.routes.url_helpers.crop_url(crop, :host => Growstuff::Application.config.host)
  return "<a href=\"#{url}\">#{crop.name}</a>"
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

end
