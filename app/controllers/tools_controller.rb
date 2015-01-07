class ToolsController < ApplicationController

  def premium_calc
    @carriers = Carrier.by_name
    authorize! :premium_calc, @carriers
  end

end
