class EventPublisher
  def initialize(route_repo = EventRoute, chan_repo = ChannelProvider, e_parser = EventParser)
    @route_repository = route_repo
    @channel_repository = chan_repo
    @event_parser = e_parser
  end

  def publish(event)
    parsed_event = @event_parser.parse(event)
    event_routes = @route_repository.for_event_uri(parsed_event.event_uri)
    @channel_repository.with_confirmed_channel do |chan|
      event_routes.each do |er|
        ex = er.resolve_exchange(chan)
        ex.publish(parsed_event.message_body, parsed_event.message_headers.merge({
          :routing_key => er.routing_key,
          :persistent => true
        }))
      end
    end
  end
end
