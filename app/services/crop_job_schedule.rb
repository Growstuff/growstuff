# frozen_string_literal: true

# When a template's jobs would fall for someone who plants a crop out on a day.
# Used to preview a template. Sowing is taken to be the same day, and the first
# harvest is worked out from the crop's median days to first harvest, if known.
class CropJobSchedule
  Entry = Struct.new(:step, :date, :past) do
    alias_method :past?, :past
  end

  def initialize(template, planting_out_on:, today: Time.zone.today)
    @template = template
    @planting_out_on = planting_out_on
    @today = today
  end

  # One entry per step, in order. A step anchored on an event that can't be
  # worked out has no date.
  def entries
    @template.steps.map do |step|
      anchor = anchor_date(step.anchor)
      date = anchor && (anchor + step.offset)
      Entry.new(step, date, date.present? && date < @today)
    end
  end

  private

  def anchor_date(anchor)
    case anchor
    when 'first_harvest'
      days = @template.crop.median_days_to_first_harvest
      @planting_out_on + days.days if days
    else
      @planting_out_on
    end
  end
end
