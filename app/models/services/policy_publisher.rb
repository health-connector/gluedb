module Services
  class PolicyPublisher
    def self.publish(q_reason_uri, p_id)
      reason = q_reason_uri.split("#").last
      reason = (reason.downcase == "renewal") ? "renewal" : "initial_enrollment"
      operation = (reason.downcase == "renewal") ? "change" : "add"
      routing_key = (reason.downcase == "renewal") ? "policy.renewal" : "policy.initial_enrollment"
      v_destination = (reason.downcase == "renewal") ? "hbx.maintenance_messages" : "hbx.enrollment_messages"

      policy = Policy.where(:id => p_id).first
      xml_body = serialize(policy, operation, reason)
      with_channel do |channel|
        channel.direct(ExchangeInformation.request_exchange, :durable => true).publish(xml_body, {
          :routing_key => routing_key,
          :headers => {
            :file_name => "#{p_id}.xml",
            :submitted_by => "trey.evans@dchbx.info",
            :vocabulary_destination => v_destination
          }
        })
      end
    end

    def self.serialize(pol, operation, reason)
      member_ids = pol.enrollees.map(&:m_id)
      serializer = CanonicalVocabulary::MaintenanceSerializer.new(
        pol,
        operation,
        reason,
        member_ids,
        member_ids
      )
      serializer.serialize
    end

    def self.with_channel
      session = Bunny.new(ExchangeInformation.amqp_uri)
      session.start
      chan = session.create_channel
      chan.prefetch(1)
      yield chan
      session.close
    end
  end
end
