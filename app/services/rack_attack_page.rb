# frozen_string_literal: true

# What Rack::Attack answers with when it blocks (403) or slows (429) a request: a page for a browser that says why and what
# to do, and a line of text for anything else. It runs before the app, so it is plain HTML with its own styles, and it
# touches no database or session. Words are in the locale files under rack_attack.
class RackAttackPage
  include ERB::Util

  # The reason to give for each blocking rule, by the key of rack_attack.blocked.reason_*; any other rule gets :other.
  REASONS = {
    'fail2ban/honeypot'     => :honeypot,
    'fail2ban/pentesters'   => :pentesters,
    'block Semrush crawler' => :semrush,
    'block configured IPs'  => :configured
  }.freeze

  STYLES = <<~CSS.squish.freeze
    body { background: #f6f4ee; color: #2b2b2b; font-family: system-ui, -apple-system, "Segoe UI", sans-serif; line-height: 1.5; margin: 0; }
    main { margin: 0 auto; max-width: 34rem; padding: 2rem 1rem; }
    a { color: #57803c; }
    .brand { font-size: 1.4rem; font-weight: 600; margin: 0 0 1rem; text-align: center; }
    .brand a { text-decoration: none; }
    .card { background: #fff; border: 1px solid #ddd; border-radius: 8px; border-top: 6px solid #57803c; padding: 1.5rem 2rem 2rem; }
    .seedling { font-size: 2.5rem; margin: 0; text-align: center; }
    h1 { color: #57803c; font-size: 1.5rem; margin: 0.25rem 0 1rem; text-align: center; }
    .reference { color: #6b6b6b; font-size: 0.8rem; margin: 1.5rem 0 0; }
  CSS

  # What a page says: its title, the reason, some advice ending in a link to `path` worded `link`.
  Content = Data.define(:title, :reason, :advice, :link, :path)

  def self.blocked(request)
    new(request).blocked
  end

  def self.throttled(request)
    new(request).throttled
  end

  def initialize(request)
    @request = request
  end

  # A Rack response: [status, headers, body].
  def blocked
    content = Content.new(title: t('blocked.title'), reason: t("blocked.reason_#{REASONS.fetch(rule, :other)}"),
                          advice: t('blocked.mistake'), link: t('blocked.contact'), path: '/about/contact')
    respond(403, "Forbidden (#{rule})\n", content)
  end

  def throttled
    content = Content.new(title: t('throttled.title'), reason: t('throttled.intro'), advice: t('throttled.wait', count: wait_minutes),
                          link: t('throttled.sign_in'), path: '/members/sign_in')
    respond(429, "Retry later\n", content, 'Retry-After' => wait_seconds.to_s)
  end

  private

  def rule
    @request.env['rack.attack.matched'].to_s
  end

  # How long until the throttle's window ends and the visitor can load pages again.
  def wait_seconds
    data = @request.env['rack.attack.match_data'] || {}
    period = data[:period].to_i
    period.positive? ? period - (data[:epoch_time].to_i % period) : 60
  end

  def wait_minutes
    (wait_seconds / 60.0).ceil
  end

  def respond(status, plain, content, headers = {})
    return [status, { 'Content-Type' => 'text/plain' }.merge(headers), [plain]] unless html?

    [status, { 'Content-Type' => 'text/html; charset=utf-8' }.merge(headers), [page(content)]]
  end

  def html?
    @request.env['HTTP_ACCEPT'].to_s.include?('text/html')
  end

  def t(key, **)
    I18n.t("rack_attack.#{key}", locale: I18n.default_locale, **)
  end

  def page(content)
    <<~HTML
      <!DOCTYPE html>
      <html lang="#{h(I18n.default_locale)}">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{h(content.title)} · Growstuff</title>
        <style>#{STYLES}</style>
      </head>
      <body>
        <main>
          <p class="brand"><a href="/">Growstuff</a></p>
          <div class="card">
            <p class="seedling" aria-hidden="true">🌱</p>
            <h1>#{h(content.title)}</h1>
            <p>#{h(content.reason)}</p>
            <p>#{h(content.advice)} <a href="#{h(content.path)}">#{h(content.link)}</a>.</p>
            #{reference}
          </div>
        </main>
      </body>
      </html>
    HTML
  end

  # The rule that answered, small at the bottom, for anyone who writes to us about it.
  def reference
    return if rule.blank?

    %(<p class="reference">#{h(t('reference', rule:))}</p>)
  end
end
