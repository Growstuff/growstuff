# frozen_string_literal: true

module Admin
  # A crop's suggested jobs, for crop wranglers to write. Gardeners who plant the
  # crop are offered the published ones.
  class CropJobTemplatesController < ApplicationController
    before_action :authenticate_member!
    before_action { authorize! :wrangle, Crop }
    before_action :set_crop
    before_action :set_template, only: %i(edit update destroy)

    def index
      @templates = CropJobTemplate.where(crop_id: crop_ids).includes(:crop, :steps).order(:name)
    end

    def new
      @template = CropJobTemplate.new(crop: @crop)
      @template.steps.build
    end

    def edit
      @template.steps.build if add_step?
      @planting_out_on = planting_out_on
    end

    def create
      @template = CropJobTemplate.new(template_params)
      return render_with_another_step(:new) if add_step?

      if @template.save
        redirect_to admin_crop_crop_job_templates_path(@crop), notice: t('crop_job_templates.created')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @template.assign_attributes(template_params)
      return render_with_another_step(:edit) if add_step?

      if @template.save
        redirect_to admin_crop_crop_job_templates_path(@crop), notice: t('crop_job_templates.saved')
      else
        @planting_out_on = planting_out_on
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      redirect_to admin_crop_crop_job_templates_path(@crop), notice: t('crop_job_templates.deleted')
    end

    private

    # The crop and its varieties: the crops a template here can be for.
    def crop_ids
      @crop_ids ||= [@crop.id] + @crop.varieties.ids
    end

    def set_crop
      @crop = Crop.find_by!(slug: params[:crop_slug])
    end

    def set_template
      @template = CropJobTemplate.where(crop_id: crop_ids).find(params[:id])
    end

    # The Add a step button saves nothing: it shows the form again, with another
    # blank step to fill in.
    def add_step?
      params[:commit] == 'add_step'
    end

    def render_with_another_step(view)
      @template.steps.build
      @planting_out_on = planting_out_on
      render view
    end

    def planting_out_on
      Date.parse(params[:planting_out_on].to_s)
    rescue Date::Error
      Time.zone.today
    end

    # The template is for the crop or one of its varieties, never another crop.
    def template_params
      permitted = params.require(:crop_job_template).permit(
        :name, :crop_id, :season, :status,
        steps_attributes: %i(id name offset_amount offset_unit direction anchor repeat position _destroy)
      )
      permitted[:crop_id] = @crop.id unless crop_ids.include?(permitted[:crop_id].to_i)
      permitted
    end
  end
end
