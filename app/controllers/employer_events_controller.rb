class EmployerEventsController < ApplicationController
  load_and_authorize_resource

  def index
    @employer_events = EmployerEvent.order_by(event_time: 1)
  end

  def download
    @carrier = Carrier.find(params[:carrier_id])

    digest_result = EmployerEvent.get_digest_or(@carrier)

    if digest_result
      send_data digest_result.last, :filename => digest_result.first, :type => :xml
    else
      render :status => 404, :nothing => true
    end
  end
end
