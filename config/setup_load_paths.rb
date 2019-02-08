# frozen_string_literal: true

if ENV['MY_RUBY_HOME']&.include?('rvm')
  begin
    require 'rvm'
    RVM.use_from_path! File.dirname(File.dirname(__FILE__))
  rescue LoadError
    # RVM is unavailable at this point.
    raise "RVM ruby lib is currently unavailable."
  end
end

# Select the correct item for which you use below.
# If you're not using bundler, remove it completely.

# If we're using a Bundler 1.0 beta
ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))
require 'bundler/setup'
