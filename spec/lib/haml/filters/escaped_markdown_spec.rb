# frozen_string_literal: true

require 'rails_helper'
require 'haml/filters'
require 'haml/filters/escaped_markdown'
require 'haml/helpers'

describe 'Haml::Filters::Escaped_Markdown' do
  it 'is registered as the handler for :escaped_markdown' do
    Haml::Filters.defined['escaped_markdown'].should ==
      Haml::Filters::EscapedMarkdown
  end

  it 'converts Markdown to escaped HTML' do
    rendered = Haml::Filters::EscapedMarkdown.render("**foo**")
    rendered.should == "&lt;p&gt;&lt;strong&gt;foo&lt;/strong&gt;&lt;/p&gt;"
  end

  it 'converts quick crop links' do
    @crop = FactoryBot.create(:crop)
    rendered = Haml::Filters::EscapedMarkdown.render("[#{@crop.name}](crop)")
    rendered.should match(/&lt;a href=&quot;/)
  end
end
