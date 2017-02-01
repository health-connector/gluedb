module EnrollmentAction
  class DependentAdd < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_added?(chunk)
    end

    def added_dependents
      action.all_member_ids - termination.all_member_ids
    end

    # TODO: Create new members, add to policy
    def persist
      members = action.policy_cv.enrollees.map(&:member)
      members_persisted = members.map do |mem|
        em = ExternalEvents::ExternalMember.new(mem)
        em.persist
      end
      unless members_persisted.all?
        return false
      end
      # Add new hbx_enrollment_id to policy
      policy_to_change = termination.existing_policy
      policy_to_change.hbx_enrollment_ids << action.hbx_enrollment_id
      policy_to_change.save
    end

    def publish
      amqp_connection = termination.event_responder.connection
      policy_to_change = termination.existing_policy
      member_date_map = {}
      policy_to_change.enrollees.each do |en|
        member_date_map[en.m_id] = en.coverage_start
      end
      change_publish_helper = EnrollmentAction::ActionPublishHelper.new(action.event_xml)
      change_publish_helper.set_policy_id(policy_to_change.eg_id)
      change_publish_helper.filter_affected_members(added_dependents)
      change_publish_helper.set_event_action("urn:openhbx:terms:v1:enrollment#change_member_add")
      change_publish_helper.set_member_starts(member_date_map)
      change_publish_helper.keep_member_ends([])
      publish_edi(amqp_connection, change_publish_helper.to_xml, termination.hbx_enrollment_id, termination.employer_hbx_id)
    end
  end
end
