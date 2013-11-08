require 'spec_helper'
require 'haml/filters'
require 'haml/filters/growstuff_markdown'

def input_link(name)
  return "[#{name}](crop)"
end

def output_link(crop)
  return "[#{crop.name}](#{Rails.application.routes.url_helpers.crop_url(crop, :host => Growstuff::Application.config.host)})"
end

describe 'Haml::Filters::Growstuff_Markdown' do
   it 'is registered as the handler for :growstuff_markdown' do
     Haml::Filters::defined['growstuff_markdown'].should ==
       Haml::Filters::GrowstuffMarkdown
   end

  it 'converts quick crop links' do
    @crop = FactoryGirl.create(:crop)
    rendered = Haml::Filters::GrowstuffMarkdown.render(input_link(@crop.name))
    rendered.should eq output_link(@crop)
  end

  it "doesn't convert nonexistent crops" do
    rendered = Haml::Filters::GrowstuffMarkdown.render(input_link("not a crop"))
    rendered.should eq "not a crop"
  end

  it "handles multiple crop links" do
    tomato = FactoryGirl.create(:tomato)
    maize = FactoryGirl.create(:maize)
    string = "#{input_link(tomato)} #{input_link(maize)}"
    rendered = Haml::Filters::GrowstuffMarkdown.render(string)
    rendered.should eq "#{output_link(tomato)} #{output_link(maize)}"
  end

end
