module EnrollmentAction
  class InitialEnrollment < Base
    extend RenewalComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      !any_renewal_candidates?(chunk.first)
    end

    def persist
      members = action.policy_cv.enrollees.map(&:member)
      members_persisted = members.map do |mem|
        em = ExternalEvents::ExternalMember.new(mem)
        em.persist
      end
      unless members_persisted.all?
        return false
      end
      ep = ExternalEvents::ExternalPolicy.new(action.policy_cv)
      ep.persist
    end

    def publish
      amqp_connection = action.event_responder.connection
      publisher = Publishers::TradingPartnerEdi.new(amqp_connection, action.event_xml)
      publish_result = false
      publish_result = publisher.publish
      if publish_result
         publisher2 = Publishers::TradingPartnerLegacyCv.new(amqp_connection, action.event_xml, action.hbx_enrollment_id, action.employer_hbx_id)
         publish_result = publisher2.publish
      end
      publish_result
    end
  end
end
