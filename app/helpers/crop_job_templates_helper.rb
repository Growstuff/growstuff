# frozen_string_literal: true

module CropJobTemplatesHelper
  # The choices for a template or step setting, as [label, value] for a select.
  def crop_job_options(attribute, values)
    values.map { |value| [crop_job_option(attribute, value), value] }
  end

  def crop_job_option(attribute, value)
    t("crop_job_templates.options.#{attribute}.#{value}")
  end

  # Who a template is for: the crop and all its varieties, or one variety.
  def crop_job_applies_to_options(crop)
    [[t('crop_job_templates.options.applies_to_all', crop: crop.name), crop.id]] +
      crop.varieties.order(:name).map { |variety| [t('crop_job_templates.options.applies_to_one', crop: variety.name), variety.id] }
  end

  # "2 weeks after planting out", for a step, or "at sowing" when it is on the day.
  def crop_job_when(step)
    anchor = crop_job_option(:anchor, step.anchor)
    return "at #{anchor}" if step.offset_amount.zero?

    "#{pluralize(step.offset_amount, step.offset_unit.singularize)} #{step.direction} #{anchor}"
  end

  # The seasons the add-jobs dialog warns about: for each template made for part of
  # the year, the months it is for where the member is. None where they haven't said
  # where they live, so there is nothing to warn about.
  def crop_job_seasons(templates, latitude)
    templates.filter_map do |template|
      months = template.season_months(latitude)
      { name: template.name, season: crop_job_option(:season, template.season).downcase, months: } if months
    end
  end
end
