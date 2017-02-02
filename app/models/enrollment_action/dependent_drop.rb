module EnrollmentAction
  class DependentDrop < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_dropped?(chunk)
    end

    # TODO: Terminate members
    def persist
      policy_to_change = termination.existing_policy
      policy_to_change.hbx_enrollment_ids << action.hbx_enrollment_id
      policy_to_change.save
      pol_updater = ExternalEvents::ExternalPolicyMemberDrop.new(policy_to_change, action.policy_cv, dropped_dependents)
      pol_updater.persist
    end

    def dropped_dependents
      termination.all_member_ids - action.all_member_ids
    end

    def publish
      amqp_connection = termination.event_responder.connection
      existing_policy = termination.existing_policy
      member_date_map = {}
      existing_policy.enrollees.each do |en|
        member_date_map[en.m_id] = en.coverage_start
      end
      termination_helper = ActionPublishHelper.new(termination.event_xml)
      termination_helper.set_event_action("urn:openhbx:terms:v1:enrollment#change_member_terminate")
      termination_helper.set_policy_id(existing_policy.eg_id)
      termination_helper.set_member_starts(member_date_map)
      termination_helper.filter_affected_members(dropped_dependents)
      termination_helper.keep_member_ends(dropped_dependents)
      # TODO: Fix money amounts - we need to pull the new money totals into the old XML
      publish_edi(amqp_connection, termination_helper.to_xml, existing_policy.eg_id, termination.employer_hbx_id)
    end
  end
end
