module HandleEnrollmentEvent
  # Create the new policy in glue
  class CreateNewPolicy
    include Interactor

    # Context Requires:
    # - policy_details (HandleEnrollmentEvent::PolicyDetails)
    # - plan_details (HandleEnrollmentEvent::PlanDetails)
    # - member_detail_collection (array of HandleEnrollmentEvent::MemberDetails)
    # - employer_details (HandleEnrollmentEvent::EmployerDetails may be nil)
    # - broker_details (HandleEnrollmentEvent::EmployerDetails may be nil)
    # Context Outputs:
    # - glue_policy (Policy)
    def call
    end

  end
end
