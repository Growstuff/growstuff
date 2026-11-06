# frozen_string_literal: true

RSpec.configure do |config|
  # `rails db:prepare` loads db/seeds.rb on a fresh database. Seeded crops,
  # roles and plant parts collide with factory data, so start from empty tables.
  # Examples are then isolated by transactional fixtures.
  config.before(:suite) do
    connection = ActiveRecord::Base.connection
    tables = connection.tables - [ActiveRecord::Base.schema_migrations_table_name,
                                  ActiveRecord::Base.internal_metadata_table_name]
    connection.truncate_tables(*tables)
  end
end
