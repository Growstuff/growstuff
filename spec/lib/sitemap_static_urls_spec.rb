# frozen_string_literal: true

require 'rails_helper'

describe 'sitemap static URLs', type: :routing do
  Rails.root.join('config/sitemap.rb').read.scan(%r{^\s*add '(/[^']*)'}).flatten.each do |path|
    it "routes #{path}" do
      expect { Rails.application.routes.recognize_path(path) }.not_to raise_error
    end
  end
end
