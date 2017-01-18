module EnrollmentAction
  class Termination < Base
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      chunk.first.is_termination?
    end

    # Remember, we only have an @termination, no @action item
    def persist
      true
    end

    def publish
      existing_policy = termination.existing_policy
      member_date_map = {}
      existing_policy.enrollees.each do |en|
        member_date_map[en.m_id] = en.coverage_start
      end
      action_helper = ActionPublishHelper.new(termination.event_xml)
      action_helper.set_event_action("urn:openhbx:terms:v1:enrollment#terminate_enrollment")
      action_helper.set_policy_id(existing_policy.eg_id)
      action_helper.set_member_starts(member_date_map)
      amqp_connection = termination.event_responder.connection
      publish_edi(amqp_connection, action_helper.to_xml, termination.hbx_enrollment_id, termination.employer_hbx_id)
    end
  end
end
