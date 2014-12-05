class Api::V2::PlansController < ApplicationController

  def show
    @plan = Plan.find(params[:id])
  end

end
