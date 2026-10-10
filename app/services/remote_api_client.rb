# frozen_string_literal: true

# A deliberately gentle client for another Growstuff instance's public JSON
# (production by default), for use by the local import tasks.
#
# Built for a server that may already be struggling:
# * one request at a time, with a pause before every request after the first
# * exponential backoff (or Retry-After, if the server sends it) on timeouts,
#   429s and 5xx responses
# * a hard stop (Aborted) rather than endless retries when a request keeps failing
# * a hard stop if the server keeps sending the same page, or too many pages
#
# Two kinds of endpoint are supported:
# * JSON:API (/api/v1/...), paged by following the server's own `links.next`
# * the site's plain JSON (/members/x/gardens.json), paged with ?page=N
class RemoteApiClient
  class Aborted < StandardError; end

  DEFAULT_SOURCE_URL = 'https://www.growstuff.org'
  USER_AGENT = 'Growstuff local import (https://github.com/Growstuff/growstuff)'
  RETRYABLE_STATUSES = [408, 429, 500, 502, 503, 504].freeze
  MAX_RETRY_AFTER = 120
  MAX_PAGES = 500

  # rubocop:disable-next Metrics/ParameterLists
  def initialize(source_url: DEFAULT_SOURCE_URL, page_size: 50, delay: 2, backoff: 5, max_retries: 3,
    out: $stdout, connection: nil, sleeper: ->(seconds) { sleep(seconds) })
    @page_size = page_size
    @delay = delay
    @backoff = backoff
    @max_retries = max_retries
    @out = out
    @sleeper = sleeper
    @connection = connection || build_connection(source_url)
    @requests_made = 0
  end

  # JSON:API list. Yields each page of resources and a 1-based page count.
  # The server may cap the page size below what we ask for, so we go by its
  # `links.next` rather than by counting.
  def each_page(path, params = {}, max_pages: nil)
    url = path
    query = { 'page[limit]' => @page_size, 'sort' => 'id' }.merge(params)
    seen_urls = Set.new
    fetched = 0

    loop do
      body = request(url, query)
      resources = jsonapi_data(body, url)
      fetched += 1
      yield resources, fetched

      next_url = body.dig('links', 'next')
      break if resources.empty? || next_url.blank? || (max_pages && fetched >= max_pages)

      guard_against_loops!(url, seen_urls, next_url, fetched)
      url = next_url
      query = nil
    end
  end

  def all(path, params = {})
    resources = []
    each_page(path, params) { |page_resources, _page| resources.concat(page_resources) }
    resources
  end

  # A single JSON:API resource, or nil if the server says it does not exist.
  def get_resource(path)
    body = request(path, {}, allow_missing: true)
    body && jsonapi_data(body, path)
  end

  # The site's plain JSON lists (an array per page, ?page=N). Yields each page
  # of rows and the page number, stopping at the first empty (or missing) page.
  def each_site_page(path, params = {}, max_pages: nil)
    previous_ids = nil
    page = 1

    loop do
      rows = request(path, params.merge('page' => page), allow_missing: page > 1)
      break if rows.blank?
      raise Aborted, "#{path} sent the same page twice; stopping." if rows.pluck('id') == previous_ids

      yield rows, page
      previous_ids = rows.pluck('id')
      page += 1
      break if max_pages && page > max_pages
      raise Aborted, "#{path} went past #{MAX_PAGES} pages; stopping." if page > MAX_PAGES
    end
  end

  def say(message)
    @out.puts message
  end

  private

  def build_connection(source_url)
    Faraday.new(url: source_url, headers: { 'User-Agent' => USER_AGENT, 'Accept' => 'application/vnd.api+json' }) do |f|
      f.options.open_timeout = 5
      f.options.timeout = 15
      f.adapter Faraday.default_adapter
    end
  end

  def jsonapi_data(body, url)
    raise Aborted, "#{url} returned an unexpected response." unless body.is_a?(Hash) && body.key?('data')

    body['data']
  end

  def guard_against_loops!(url, seen_urls, next_url, fetched)
    raise Aborted, "#{url} keeps linking to the same next page; stopping." if next_url == url || !seen_urls.add?(next_url)
    raise Aborted, "#{url} went past #{MAX_PAGES} pages; stopping." if fetched >= MAX_PAGES

    host = @connection.url_prefix.host
    return if host.nil? || URI.parse(next_url).host == host

    raise Aborted, "#{url} linked to another host (#{next_url}); not following it."
  end

  def request(url, query, allow_missing: false)
    @sleeper.call(@delay) if @requests_made.positive?
    @requests_made += 1

    (0..@max_retries).each do |attempt|
      response = get(url, query)
      return JSON.parse(response.body) if response&.success?
      return nil if allow_missing && response&.status == 404

      problem = response ? "HTTP #{response.status}" : 'network error'
      raise Aborted, "#{url} failed with #{problem}. Not retrying." unless response.nil? || RETRYABLE_STATUSES.include?(response.status)

      if attempt == @max_retries
        raise Aborted, "#{url} still failing (#{problem}) after #{@max_retries} retries. " \
                       'Leaving the server alone; try again later.'
      end

      wait = retry_delay(response, attempt)
      say "#{url}: #{problem}, waiting #{wait}s before retry #{attempt + 1}/#{@max_retries}"
      @sleeper.call(wait)
    end
  rescue JSON::ParserError
    raise Aborted, "#{url} returned something that is not JSON."
  end

  def get(url, query)
    @connection.get(url, query)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
    nil
  end

  def retry_delay(response, attempt)
    retry_after = response&.headers&.[]('Retry-After').to_i
    return [retry_after, MAX_RETRY_AFTER].min if retry_after.positive?

    @backoff * (2**attempt)
  end
end
