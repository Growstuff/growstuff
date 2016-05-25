module SimpleShow
  extend ActiveSupport::Concern

  module ClassMethods

    def show
      @me = self.find(params[:id])

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @me }
      end
    end
  end
end
