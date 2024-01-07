# frozen_string_literal: true

class WeatherObservationsController < DataController
    def index
      @owner = Member.find_by(slug: params[:member_slug])
      @show_all = params[:all] == '1'
      @show_jump_to = params[:member_slug].present? ? true : false
  
    #   @weather_observations = @weather_observations.includes(:owner)
      #   @weather_observations = @weather_observations.active unless @show_all
      #   @weather_observations = @weather_observations.where(owner: @owner) if @owner.present?
      #   @weather_observations = @weather_observations.where.not(members: { confirmed_at: nil })
        # .order(:name).paginate(page: params[:page])
      respond_with(@weather_observations)
    end
  
    def show
      respond_with(@weather_observation)
    end
  
    def new
      @weather_observation = WeatherObservation.new
      respond_with(@weather_observation)
    end
  
    def edit
      respond_with(@weather_observation)
    end
  
    def create
      @weather_observation.owner_id = current_member.id
      flash[:notice] = I18n.t('weather_observations.created') if @weather_observation.save
      respond_with(@weather_observation)
    end
  
    def update
      flash[:notice] = I18n.t('weather_observations.updated') if @weather_observation.update(weather_observation_params)
      respond_with(@weather_observation)
    end
  
    def destroy
      @weather_observation.destroy
      flash[:notice] = I18n.t('weather_observations.deleted')
      redirect_to(member_weather_observations_path(@weather_observation.owner))
    end
  
    private
  
    def weather_observation_params
      params.require(:weather_observation).permit!
    end
  end
  