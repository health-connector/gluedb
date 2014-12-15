module Services
  class PolicyPublisher
    def self.publish_cancel(p_id)
      ::Workflow::CancelPolicy.new.call(pid)
    end

    def self.publish(q_reason_uri, p_id)
      policy = Policy.where(:id => p_id).first
      p_action = policy_action(policy)
      reason = (p_action.downcase == "renewal") ? "renewal" : "initial_enrollment"
      operation = (p_action.downcase == "renewal") ? "change" : "add"
      routing_key = (p_action.downcase == "renewal") ? "policy.renewal" : "policy.initial_enrollment"
      v_destination = (p_action.downcase == "renewal") ? "hbx.maintenance_messages" : "hbx.enrollment_messages"

      xml_body = serialize(policy, operation, reason)
      with_channel do |channel|
        channel.direct(ExchangeInformation.request_exchange, :durable => true).publish(xml_body, {
          :routing_key => routing_key,
          :reply_to => v_destination,
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

    def self.policy_action(policy)
      subscriber = policy.subscriber
      coverage_start = subscriber.coverage_start
      sub_person = subscriber.person
      has_renewal_match = sub_person.policies.any? do |pol|
        (pol.plan.coverage_type == policy.plan.coverage_type) &&
          pol.active_as_of?(coverage_start - 1.day) &&
          (pol.id != policy.id)
      end
      has_renewal_match ? "renewal" : "initial_enrollment"
    end
  end
end
