
module EnrollmentAction
class CobraReinstate < Base
  extend PlanComparisonHelper
  extend DependentComparisonHelper
  def self.qualifies?(chunk)
    return false if chunk.length > 1
    chunk.first.is_cobra_reinstate? && existing_policy.present? && existing_policy.terminated?
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
    amqp_connection = action.event_responder.connection
    action_helper = EnrollmentAction::ActionPublishHelper.new(action.event_xml)
    action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#cobra_reinstate")
    action_helper.keep_member_ends([])
    publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id)
  end
end