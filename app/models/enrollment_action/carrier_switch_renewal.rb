module EnrollmentAction
  class CarrierSwitchRenewal < Base
    extend RenewalComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      renewal_candidates = other_carrier_renewal_candidates(chunk.first)
      !renewal_candidates.empty?
    end
=begin
    def persist
      other_carrier_renewal_candidates = self.class.other_carrier_renewal_candidates(action)
      members = action.policy_cv.enrollees.map(&:member)
      members_persisted = members.map do |mem|
        em = ExternalEvents::ExternalMember.new(mem)
        em.persist
      end
      unless members_persisted.all?
        return false
      end
      ep = ExternalEvents::ExternalPolicy.new(action.policy_cv, action.existing_plan)
      return false unless ep.persist
      termination_results = other_carrier_renewal_candidates.map do |rc|
        rc.terminate_as_of(action.subscriber_start - 1.day)
      end 
      termination_results.all?
    end

    def publish
      # TODO: Publish current carrier term
      amqp_connection = termination.event_responder.connection
      action_helper = EnrollmentAction::ActionPublishHandler.new(action.event_xml)
      action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#initial")
      action_helper.keep_member_ends([])
      publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id)
    end
=end
  end
end
