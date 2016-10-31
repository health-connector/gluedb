module HandlePolicyNotification
  class FindInteractingPolicies
    include Interactor

    # Context requires:
    # - policy_details (Openhbx::Cv2::Policy)
    # - plan_details (HandlePolicyNotification::PlanDetails)
    # - employer_details (HandlePolicyNotification::EmployerDetails)
    # - member_detail_collection (array of HandlePolicyNotification::MemberDetails)
    # Context outputs:
    # - interacting_policies (array of Policy, may be empty)
    def call
      subscriber_member_details = member_detail_collection.detect { |md| md.is_subscriber? }
      subscriber_member = Person.where("members.hbx_assigned_id" => subscriber_member_details.member_id).first
      coverage_start = subscriber_member_details.coverage_start
      coverage_end = subscriber_member_details.coverage_end
      if policy_details.market == "shop"
      else
      end
    end
  end
end
