class AlternateNamesController < ApplicationController
  load_and_authorize_resource

  # GET /alternate_names/1/edit
  def edit
    @alternate_name = AlternateName.find(params[:id])
  end
end
