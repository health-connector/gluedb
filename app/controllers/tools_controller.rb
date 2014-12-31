class ToolsController < ApplicationController

  load_and_authorize_resource

  def premium_calc
    @carriers = Carrier.by_name
  end

end
