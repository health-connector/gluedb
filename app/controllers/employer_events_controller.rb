class EmployerEventsController < ApplicationController
  load_and_authorize_resource

  def index
    @employer_events = EmployerEvent.order_by(event_time: 1)
  end

  def download
    zip_path = EmployerEvent.get_all_digests

    begin
      send_data File.read(zip_path), :filename => "carrier_events.zip"
    ensure
      FileUtils.rm_f(zip_path)
    end
  end
end
