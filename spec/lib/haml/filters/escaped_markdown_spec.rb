require 'spec_helper'
require 'haml/filters'
require 'haml/filters/escaped_markdown'
require 'haml/helpers'

def input_link(name)
  return "[#{name}](crop)"
end

def output_link(crop)
  url = Rails.application.routes.url_helpers.crop_url(crop, :host => Growstuff::Application.config.host)
  return Haml::Helpers.html_escape "<a href=\"#{url}\">#{crop.name}</a>"
end

describe 'Haml::Filters::Escaped_Markdown' do
  it 'is registered as the handler for :escaped_markdown' do
    Haml::Filters::defined['escaped_markdown'].should ==
      Haml::Filters::EscapedMarkdown
  end

  it 'converts Markdown to escaped HTML' do
    rendered = Haml::Filters::EscapedMarkdown.render("**foo**")
    rendered.should == "&lt;p&gt;&lt;strong&gt;foo&lt;/strong&gt;&lt;/p&gt;"
  end

  it 'converts quick crop links' do
    @crop = FactoryGirl.create(:crop)
    rendered = Haml::Filters::EscapedMarkdown.render(input_link(@crop.name))
    rendered.should match /#{output_link(@crop)}/
  end

end
