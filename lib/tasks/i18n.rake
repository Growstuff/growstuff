# frozen_string_literal: true

namespace :i18n do
  desc "sort all i18n locale keys"
  task :normalize do
    `i18n-tasks normalize`
  end

  desc "translate haml strings into i18 en locale using haml-i18n-extractor"
  task :extractor, [:haml_path] do |_t, args|
    require 'haml-i18n-extractor'
    haml_path = args[:haml_path]
    begin
      translate = Haml::I18n::Extractor.new(haml_path)
      translate.run
    rescue Haml::I18n::Extractor::InvalidSyntax
      puts "There was an error with #{haml_path}"
    end
  end
end
