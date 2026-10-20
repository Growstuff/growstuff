# frozen_string_literal: true

# Trigram indexes for crop search (see SearchCrops). Each name table gets a
# stored column holding the name lower-cased with accents folded (translate(),
# because unaccent() is not immutable and so cannot be used here), and a GIN
# index on it.
class AddCropNameSearchIndexes < ActiveRecord::Migration[8.1]
  ACCENTED = "àáâãäåāçćčèéêëēėęìíîïīįłñńòóôõöøōùúûüūýÿžźż"
  PLAIN = "#{'a' * 7}ccc#{'e' * 7}#{'i' * 6}lnn#{'o' * 7}#{'u' * 5}yyzzz".freeze
  NORMALISED = "translate(lower(name), '#{ACCENTED}', '#{PLAIN}')".freeze

  TABLES = %i(crops alternate_names scientific_names).freeze

  def change
    TABLES.each do |table|
      add_column table, :normalised_name, :virtual, type: :text, as: NORMALISED, stored: true
      add_index table, :normalised_name, using: :gin, opclass: :gin_trgm_ops
    end
  end
end
