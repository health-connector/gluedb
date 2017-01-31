module EnrollmentAction
  class PlanChange < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false if same_plan?(chunk)
      (!carriers_are_different?(chunk)) && !dependents_changed?(chunk)
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
      return false unless ep.persist
      policy_to_term = termination.existing_policy
      policy_to_term.terminate_as_of(termination.subscriber_end)
    end

    def publish
      amqp_connection = action.event_responder.connection
      action_helper = EnrollmentAction::ActionPublishHelper.new(action.event_xml)
      action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#change_product")
      action_helper.keep_member_ends([])
      publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id)
    end
  end
end
