class EmployerEventsController < ApplicationController
  load_and_authorize_resource

  def index
    @employer_events = EmployerEvent.order_by(event_time: 1)
  end

  def publish
    ec = ExchangeInformation
    connection = AmqpConnectionProvider.start_connection
    broadcaster = Amqp::EventBroadcaster.new(connection)
    broadcaster.broadcast({
      :routing_key => "info.events.trading_partner.employer_digest.requested"
    }, "")
    connection.close
    redirect_to employer_events_path
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
