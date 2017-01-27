module EnrollmentAction
  class PassiveRenewal < Base
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      chunk.first.is_passive_renewal?
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
      ep = ExternalEvents::ExternalPolicy.new(action.policy_cv, action.existing_plan)
      ep.persist
    end

    def publish
      amqp_connection = termination.event_responder.connection
      action_helper = EnrollmentAction::ActionPublishHandler.new(action.event_xml)
      action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#auto_renew")
      action_helper.keep_member_ends([])
      publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id)
    end
  end
end
