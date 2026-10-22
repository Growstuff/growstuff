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

  # "2 weeks after planting out", for a step.
  def crop_job_when(step)
    "#{step.offset_amount} #{step.offset_unit} #{step.direction} #{crop_job_option(:anchor, step.anchor)}"
  end
end
