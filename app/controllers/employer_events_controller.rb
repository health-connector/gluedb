class EmployerEventsController < ApplicationController
  load_and_authorize_resource

  def index
    @employer_events = EmployerEvent.order_by(event_time: 1)
  end

  def publish
    ec = ExchangeInformation
    connection = AmqpConnectionProvider.start_connection
    EmployerEvent.with_digest_payloads do |payload|
      Amqp::ConfirmedPublisher.with_confirmed_channel(connection) do |chan|
        ex = chan.fanout(ec.event_publish_exchange, {:durable => true})
        ex.publish(
          payload,
          {routing_key: "info.events.trading_partner.employer_digest.published"}
        )
      end
    end
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
