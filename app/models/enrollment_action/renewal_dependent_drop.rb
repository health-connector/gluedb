module EnrollmentAction
  class RenewalDependentDrop < Base
    extend RenewalComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      renewal_candidates = same_carrier_renewal_candidates(chunk.first)
      return false if renewal_candidates.empty?
      renewal_dependents_dropped?([renewal_candidates.first, chunk.first])
      has_same_carrier_renewal_candidates?(chunk.first) && dependents_dropped?(chunk.first)
    end

    def dropped_dependents
      renewal_candidates = self.class.same_carrier_renewal_candidates(action)
      renewal_candidates.first.enrollees.map(&:m_id) - action.all_member_ids
    end

=begin 
    def persist
      renewal_candiddates = self.class.same_carrier_renewal_candiddates(action)
      members = action.policy_cv.enrollees.map(&:member)
      members_persisted = members.map do |mem|
        em = ExternalEvents::ExternalMember.new(mem)
        em.persist
      end
      unless members_persisted.all?
        return false
      end
      ep = ExternalEvents::ExternalPolicy.new(action.policy_cv)
      return false unless ep.persist
      # TODO: Term affected members from other policy
    end

    def publish
      # TODO: Publish dependent termination transaction
      amqp_connection = termination.event_responder.connection
      action_helper = EnrollmentAction::ActionPublishHandler.new(action.event_xml)
      action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#active_renew")
      action_helper.filter_affected_members(added_dependents)
      publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id)
    end
=end
  end
end
