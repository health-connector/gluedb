module HandleEnrollmentEvent
  # Update the glue policy
  class UpdatePolicy
    include Interactor

    # Context Requires:
    # - policy_details (HandleEnrollmentEvent::PolicyDetails)
    # - plan_details (HandleEnrollmentEvent::PlanDetails)
    # - member_detail_collection (array of HandleEnrollmentEvent::MemberDetails)
    # - member_changes_collection (array of HandleEnrollmentEvent::MemberChange)
    # - employer_details (HandleEnrollmentEvent::EmployerDetails may be nil)
    # - broker_details (HandleEnrollmentEvent::EmployerDetails may be nil)
    # Context Outputs:
    # - glue_policy (Policy)
    def call
    end

  end
end
