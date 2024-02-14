module EnrollmentAction
  class ActiveRenewal < Base
    extend DependentComparisonHelper
    extend RenewalComparisonHelper

    def self.qualifies?(chunk)
      return false if chunk.length > 1

      record = chunk.first
      return false if record.is_termination?
      return false if record.is_passive_renewal?
      return false if record.is_reinstate_canceled?

      renewal_candidates = same_carrier_renewal_candidates(record)
      return false if renewal_candidates.empty?
      !renewal_dependents_changed?(renewal_candidates.first, record)
    end

    def persist
      return false if check_already_exists
      members = action.policy_cv.enrollees.map(&:member)
      members_persisted = members.map do |mem|
        em = ExternalEvents::ExternalMember.new(mem)
        em.persist
      end
      unless members_persisted.all?
        return false
      end
      ep = ExternalEvents::ExternalPolicy.new(action.policy_cv, action.existing_plan, action.is_cobra?)
      ep.persist
    end

    def publish
      amqp_connection = action.event_responder.connection
      action_helper = EnrollmentAction::ActionPublishHelper.new(action.event_xml)
      action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#active_renew")
      action_helper.keep_member_ends([])
      publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id)
    end

  end
end
