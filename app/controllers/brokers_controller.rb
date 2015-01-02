class BrokersController < ApplicationController

  load_and_authorize_resource

  def index
    @q = params[:q]

    if params[:q].present?
      @brokers = Broker.by_name.search(@q).page(params[:page]).per(12)
    else
      @brokers = Broker.by_name.page(params[:page]).per(12)
    end

    respond_to do |format|
	    format.html # index.html.erb
	    format.json { render json: @brokers }
	  end
  end

  def show
		@broker = Broker.find(params[:id])
		@employers = @broker.employers.by_name

	  respond_to do |format|
		  format.html # index.html.erb
		  format.json { render json: @broker }
		end
  end
end
