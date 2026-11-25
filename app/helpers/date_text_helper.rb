# frozen_string_literal: true

# A date for a sentence or a label, in a short form that leaves the year out. A date more than a year ago is ambiguous without
# it, so then it gets the year.
module DateTextHelper
  # pattern is the short form ("%b %d") and year_pattern the same with the year ("%b %d, %Y").
  def date_text(date, pattern, year_pattern, today: Time.zone.today)
    l(date, format: date < today - 1.year ? year_pattern : pattern)
  end

  # "Jan 04" or, from over a year ago, "Jan 04, 2000".
  def month_day_text(date)
    date_text(date, '%b %d', '%b %d, %Y')
  end
end
