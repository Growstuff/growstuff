# frozen_string_literal: true

# Copies approved crops from another Growstuff instance (production by
# default) into the local database, using its public JSON:API. All the
# network gentleness (pacing, backoff, giving up) lives in RemoteApiClient.
#
# Re-running is safe: crops are matched by name, so existing ones are updated
# rather than duplicated.
class CropImportService
  class Aborted < StandardError; end

  DEFAULT_SOURCE_URL = RemoteApiClient::DEFAULT_SOURCE_URL
  CROPS_PATH = '/api/v1/crops'

  def initialize(max_pages: nil, reindex: true, out: $stdout, client: nil, **client_options)
    @max_pages = max_pages
    @reindex = reindex
    @out = out
    @client = client || RemoteApiClient.new(out: out, **client_options)
    @stats = Hash.new(0)
    @local_ids_by_remote_id = {}
    @remote_parent_ids = {}
  end

  def call
    # Skip per-record Elasticsearch updates; we reindex once at the end.
    Searchkick.callbacks(false) { import_pages }
    link_parents
    @stats
  rescue RemoteApiClient::Aborted => e
    raise Aborted, "#{e.message} Re-running is safe: crops already imported are just updated."
  ensure
    Crop.reindex if @reindex
  end

  # Imports a single JSON:API crop resource, returning the local Crop, or nil
  # if it could not be saved.
  def import_resource(resource)
    attributes = resource['attributes']
    crop = Crop.approved.find_or_initialize_by(name: attributes['name'])
    outcome = crop.new_record? ? :created : :updated

    crop.assign_attributes(
      en_wikipedia_url:             attributes['en-wikipedia-url'],
      perennial:                    attributes['perennial'],
      median_lifespan:              attributes['median-lifespan'],
      median_days_to_first_harvest: attributes['median-days-to-first-harvest'],
      median_days_to_last_harvest:  attributes['median-days-to-last-harvest']
    )

    if !crop.new_record? && !crop.changed?
      outcome = :unchanged
    elsif !crop.save
      @stats[:failed] += 1
      @out.puts "  skipped #{attributes['name'].inspect}: #{crop.errors.full_messages.to_sentence}"
      return nil
    end

    @stats[outcome] += 1
    remember_parent(resource, crop)
    crop
  end

  private

  def import_pages
    @client.each_page(CROPS_PATH, max_pages: @max_pages) do |resources, page|
      resources.each { |resource| import_resource(resource) }
      @out.puts "page #{page}: #{resources.size} crops (#{stats_summary})"
    end
  end

  # The API only sends the parent's id when asked to include it, so this is
  # best-effort: it links parents whenever the response carries them.
  def remember_parent(resource, crop)
    @local_ids_by_remote_id[resource['id']] = crop.id
    remote_parent_id = resource.dig('relationships', 'parent', 'data', 'id')
    @remote_parent_ids[crop.id] = remote_parent_id if remote_parent_id
  end

  # Remote ids mean nothing locally, so parents are wired up at the end, and
  # only for parents that were seen during this run.
  def link_parents
    @remote_parent_ids.each do |crop_id, remote_parent_id|
      parent_id = @local_ids_by_remote_id[remote_parent_id]
      if parent_id
        Crop.where(id: crop_id).update_all(parent_id: parent_id) # rubocop:disable Rails/SkipsModelValidations
      else
        @stats[:parent_not_found] += 1
      end
    end
  end

  def stats_summary
    @stats.map { |key, count| "#{count} #{key.to_s.tr('_', ' ')}" }.join(', ')
  end
end
