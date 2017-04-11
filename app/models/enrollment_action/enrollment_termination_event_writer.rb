module EnrollmentAction
  class EnrollmentTerminationEventWriter
    attr_reader :affected_members, :policy, :enrollees

    def initialize(policy, affected_member_ids)
      @enrollees = policy.enrollees.select do |en|
        affected_member_ids.include?(en.m_id)
      end
      @affected_members = @enrollees.map do |en|
        ::BusinessProcesses::AffectedMember.new({
          :policy => policy,
          :member_id => en.m_id
        })
      end
      @policy = policy
    end

    def write(transaction_id, event_type)
      cont = ApplicationController.new
      @writer_result ||= cont.render_to_string(
          :layout => "enrollment_event",
          :partial => "enrollment_events/enrollment_event",
          :format => :xml,
          :locals => {
            :affected_members => affected_members,
            :policy => policy,
            :enrollees => enrollees,
            :event_type => event_type,
            :transaction_id => transaction_id
          })
      @writer_result
    end
  end
end
