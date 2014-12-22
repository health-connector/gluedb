module Listeners
  class PersonMatcher < Amqp::Client

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.glue.person_matcher"
    end

    def validate(delivery_info, properties, payload)
      if properties.reply_to.blank?
        add_error("Reply to is empty.")
      end
    end

    def on_message(delivery_info, properties, payload)
      reply_to = properties.reply_to
      headers = properties.headers

      person_hash = {
        name_first: headers["name_first"],
        name_last: headers["name_last"],
        hbx_member_id: headers["hbx_member_id"],
        ssn: headers["ssn"],
        dob: headers["dob"],
        email: headers["email"]
      }

      begin
        person, member = PersonMatchStrategies::Finder.find_person_and_member(person_hash)
        if person.blank? || member.blank?
          channel.default_exchange.publish(JSON.dump(person_hash),error_properties(reply_to, "404","not found"))
        else
          channel.default_exchange.publish(ApplicationController.new.render_to_string(partial: 'shared/v2/person_match', locals: { person: p, member: m}),response_properties(reply_to, "200"))
        end
      rescue PersonMatchStrategies::AmbiguiousMatchError => e
        channel.default_exchange.publish(JSON.dump(person_hash),error_properties(reply_to, "409",e.message))
      end
      channel.ack(delivery_info.delivery_tag, false)
    end

    def response_properties(reply_to, status)
      {
        headers: {
          return_status: status
        },
        routing_key: reply_to
      }
    end

    def error_properties(reply_to, status, message)
      {
        headers: {
          return_status: status,
          error_message: message
        },
        routing_key: reply_to
      }
    end

    def self.run
      conn = Bunny.new(ExchangeInformation.amqp_uri)
      conn.start
      chan = conn.create_channel
      chan.prefetch(1)
      q = chan.queue(self.queue_name, :durable => true)
      self.new(chan, q).subscribe(:block => true, :manual_ack => true)
    end
  end
end
