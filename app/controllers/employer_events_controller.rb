class EmployerEventsController < ApplicationController
  load_and_authorize_resource

  def index
    @employer_events = EmployerEvent.order_by(event_time: 1)
  end

  def download
    @carrier = Carrier.find(params[:carrier_id])

    send_data EmployerEvent.get_digest_for(@carrier), :file_name => "#{@carrier.abbrev}.xml", :type => :xml
  end
end
