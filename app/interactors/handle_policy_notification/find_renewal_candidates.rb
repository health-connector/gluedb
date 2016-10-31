module HandlePolicyNotification
  class FindRenewalCandidates
    include Interactor

    # Context requires:
    # - policy_details
    # - plan_details (HandlePolicyNotification::PlanDetails)
    # - member_detail_collection (array of HandlePolicyNotification::MemberDetails)
    # Context outputs:
    # - renewal_policies (a potentially empty array of Policy)
    def call
      context.renewal_policies = []
    end
  end
end
