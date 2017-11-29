
module EnrollmentAction
class CobraReinitiate < Base
  extend PlanComparisonHelper
  extend DependentComparisonHelper
  def self.qualifies?(chunk)
    return false if chunk.length < 2      
    return false unless same_plan?(chunk)
    chunk.first.is_termination?
  end

  def persist
   # if termination.existing_policy
   #   policy_to_term = termination.existing_policy
   #   policy_to_term.terminate_as_of(termination.subscriber_end)
   # end

    policy_to_change = action.existing_policy
    unless policy_to_change.is_cobra?
      policy_to_change.terminate_as_of(termination.subscriber_end)
      
      policy_to_change.hbx_enrollment_ids << action.hbx_enrollment_id
      policy_to_change.save
    end

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
    amqp_connection = action.event_responder.connection
    action_helper = EnrollmentAction::ActionPublishHelper.new(action.event_xml)
    action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#cobra_reinstate")
    action_helper.keep_member_ends([])
    publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id)
  end
end