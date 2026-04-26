# frozen_string_literal: true

namespace :maintenance do
  desc "Run maintenance tasks"
  task cleanup: :environment do
    puts "Starting maintenance cleanup..."

    # a. Executes the gardens:archive task
    puts "Archiving old gardens and plantings..."
    Rake::Task["gardens:archive"].invoke

    # b. Calls reindex on Planting, Seed, and Activity
    puts "Reindexing Planting, Seed, and Activity to remove old inactive records from Elasticsearch..."
    Planting.reindex
    Seed.reindex
    Activity.reindex

    # c. Identifies fragmented database indexes and reindexes them
    puts "Reindexing fragmented database indexes..."
    reindex_fragmented_indexes

    # d. Consolidates Elasticsearch shards
    puts "Consolidating Elasticsearch shards..."
    consolidate_elasticsearch_shards

    puts "Maintenance cleanup complete."
  end

  def reindex_fragmented_indexes
    # Query to find fragmented indexes with significant bloat.
    # Targets indexes with > 20% bloat and size > 10MB.
    bloat_query = <<~SQL
      SELECT
        indexname,
        index_size,
        bloat_ratio
      FROM (
        SELECT
          schemaname, tablename, indexname,
          (avg_width * tuple_count)::bigint AS index_size,
          (CASE WHEN relpages > 0 THEN (1 - (bloat_pages::numeric / relpages::numeric)) * 100 ELSE 0 END) AS bloat_ratio
        FROM (
          SELECT
            n.nspname AS schemaname,
            ct.relname AS tablename,
            i.relname AS indexname,
            (SELECT avg(width) FROM pg_stats WHERE schemaname = n.nspname AND tablename = ct.relname) AS avg_width,
            ct.reltuples AS tuple_count,
            i.relpages AS relpages,
            CEIL((ct.reltuples * (SELECT avg(width) FROM pg_stats WHERE schemaname = n.nspname AND tablename = ct.relname)) / current_setting('block_size')::numeric) AS bloat_pages
          FROM pg_index x
          JOIN pg_class ct ON x.indrelid = ct.oid
          JOIN pg_class i ON x.indexrelid = i.oid
          JOIN pg_namespace n ON ct.relnamespace = n.oid
          WHERE n.nspname = 'public'
            AND ct.relkind = 'r'
            AND i.relkind = 'i'
        ) AS sub
      ) AS sub2
      WHERE bloat_ratio > 20 AND index_size > 10000000
    SQL

    begin
      results = ActiveRecord::Base.connection.execute(bloat_query)
      if results.any?
        results.each do |row|
          index_name = row['indexname']
          puts "Reindexing fragmented index: #{index_name} (Size: #{row['index_size']}, Bloat: #{row['bloat_ratio'].to_f.round(2)}%)"
          begin
            # REINDEX INDEX CONCURRENTLY is available since PostgreSQL 12
            ActiveRecord::Base.connection.execute("REINDEX INDEX CONCURRENTLY #{index_name}")
          rescue ActiveRecord::StatementInvalid => e
            puts "Could not reindex #{index_name}: #{e.message}"
          end
        end
      else
        puts "No significantly fragmented indexes found."
      end
    rescue ActiveRecord::StatementInvalid => e
      puts "Error querying for fragmented indexes: #{e.message}"
      puts "Falling back to safe maintenance mode."
    end
  end

  def consolidate_elasticsearch_shards
    models = [Crop, Planting, Harvest, Seed, Activity, Photo]
    models.each do |model|
      puts "Consolidating shards for #{model.name}..."
      begin
        index_name = model.searchkick_index.name
        # forcemerge is an expensive operation, max_num_segments: 1 consolidates to a single segment.
        Searchkick.client.indices.forcemerge(index: index_name, max_num_segments: 1)
      rescue StandardError => e
        puts "Could not consolidate shards for #{model.name}: #{e.message}"
      end
    end
  end
end
