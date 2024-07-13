# frozen_string_literal: true

require 'rails_helper'
require 'haml/filters'
require 'haml/filters/escaped_markdown'
require 'haml/helpers'

describe 'Haml::Filters::Escaped_Markdown' do
  it 'is registered as the handler for :escaped_markdown' do
    Haml::Filters.registered[:escaped_markdown].should ==
      Haml::Filters::EscapedMarkdown
  end

  it 'converts Markdown to escaped HTML' do
    template = <<~HTML
      :escaped_markdown
        **foo**
    HTML
    rendered = render_haml(template)
    expect(rendered).to eq "&lt;p&gt;&lt;strong&gt;foo&lt;/strong&gt;&lt;/p&gt;\n\n"
  end

  it 'converts quick crop links' do
    @crop = FactoryBot.create(:crop)
    template = <<~HTML
      :escaped_markdown
        [#{@crop.name}](crop)
    HTML
    rendered = render_haml(template)
    expect(rendered).to match(/&lt;a href=&quot;/)
  end

  def render_haml(haml)
    locals = {}
    options = {}
    Haml::Template.new(options) { haml }.render(Object.new, locals)
  end
end
