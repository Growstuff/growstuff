# frozen_string_literal: true

# How the admin climate coverage screens show a status. Each has its own icon as well as its own colour, so it can be told
# apart without seeing colour: a tick, a clock, a cross and a dash.
module ClimateCoverageHelper
  ICONS = {
    ClimateCoverage::COVERED   => 'circle-check',
    ClimateCoverage::STALE     => 'clock',
    ClimateCoverage::MISSING   => 'circle-xmark',
    ClimateCoverage::UNLOCATED => 'circle-minus'
  }.freeze

  # text-bg-* picks the text colour that is readable on the fill, as a bare badge here inherits its text colour.
  BADGES = {
    ClimateCoverage::COVERED   => 'success',
    ClimateCoverage::STALE     => 'warning',
    ClimateCoverage::MISSING   => 'danger',
    ClimateCoverage::UNLOCATED => 'secondary'
  }.freeze

  def climate_status_icon(status)
    icon('fas', ICONS.fetch(status), class: 'me-1')
  end

  def climate_status_label(status)
    t("admin.climate_coverage.statuses.#{status}")
  end

  def climate_status_badge(status)
    tag.span(class: "badge text-bg-#{BADGES.fetch(status)}") { climate_status_icon(status) + climate_status_label(status) }
  end
end
