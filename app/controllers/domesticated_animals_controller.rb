# frozen_string_literal: true

class DomesticatedAnimalsController < ApplicationController
  include FeatureGated

  require_feature :domesticated_animals

  before_action :authenticate_member!, except: :show
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  def show
    @jobs = @domesticated_animal.jobs.accessible_by(current_ability)
      .preload(:owner, :garden, :jobbable).order(:due_date, :id)
    respond_with @domesticated_animal
  end

  def new
    @domesticated_animal.owner = current_member
    return render partial: 'form', locals: { dialog: true } if params[:dialog] == 'true'

    respond_with @domesticated_animal
  end

  def edit
    respond_with @domesticated_animal
  end

  def create
    @domesticated_animal.owner = current_member
    return render_errors(:new) unless @domesticated_animal.save

    respond_with @domesticated_animal
  end

  def update
    return render_errors(:edit) unless @domesticated_animal.update(domesticated_animal_params)

    respond_with @domesticated_animal
  end

  def destroy
    @domesticated_animal.destroy
    respond_with @domesticated_animal, location: member_path(@domesticated_animal.owner)
  end

  private

  def render_errors(template)
    respond_to do |format|
      format.html do
        if params[:dialog] == 'true'
          render partial: 'form', locals: { dialog: true }, status: :unprocessable_content
        else
          render template, status: :unprocessable_content
        end
      end
      format.json { render json: @domesticated_animal.errors, status: :unprocessable_content }
    end
  end

  def domesticated_animal_params
    params.require(:domesticated_animal).permit(
      :name, :species, :category, :description, :date_of_birth, :date_of_death, :biological_sex, :alignment
    )
  end
end
