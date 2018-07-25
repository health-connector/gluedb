module EnrollmentAction
  class PlanChangeDependentDrop < Base
    extend PlanComparisonHelper
    extend DependentComparisonHelper
    include TerminationDateHelper

    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false if same_plan?(chunk)
      (!carriers_are_different?(chunk)) && dependents_dropped?(chunk)
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
      return false unless ep.persist
      termination_date = select_termination_date
      policy_to_term = termination.existing_policy
      policy_to_term.terminate_as_of(termination_date)
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
      termination_helper.set_member_ends(select_termination_date)
      termination_helper.swap_qualifying_event(action.event_xml)
      termination_helper.recalculate_premium_totals_excluding_dropped_dependents(action.all_member_ids)
      publish_result, publish_errors = publish_edi(amqp_connection, termination_helper.to_xml, existing_policy.eg_id, termination.employer_hbx_id, termination.workflow_id)
      unless publish_result
        return([publish_result, publish_errors])
      end
      action_helper = EnrollmentAction::ActionPublishHelper.new(action.event_xml)
      action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#change_product")
      action_helper.keep_member_ends([])
      publish_edi(amqp_connection, action_helper.to_xml, action.hbx_enrollment_id, action.employer_hbx_id, action.workflow_id)
    end
  end
end
