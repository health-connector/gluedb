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
      subscriber_member_details = context.member_detail_collection.detect { |md| md.is_subscriber? }
      subscriber_person = Person.where("members.hbx_assigned_id" => subscriber_member_details.member_id).first
      coverage_start = subscriber_member_details.coverage_start
      coverage_end = subscriber_member_details.coverage_end
      possible_matches = []
      if context.policy_details.market == "shop"
        possible_matches = subscriber_person.policies.select do |pol|
          (pol.plan.market_type == "shop") &&
            (pol.plan.coverage_type == context.plan_details.found_plan_coverage_type) &&
            (pol.employer.id == context.employer_details.found_employer.id) &&
            shop_dates_overlap(pol, context.employer_details.found_employer, coverage_start, coverage_end)
        end
      else
        possible_matches = subscriber_person.policies.select do |pol|
          (pol.plan.market_type != "shop") &&
            (pol.plan.coverage_type == context.plan_details.found_plan_coverage_type) &&
            ivl_dates_overlap(coverage_start, coverage_end, pol.policy_start, pol.policy_end)
        end
      end
      context.interacting_policies = possible_matches.reject { |pol| pol.canceled? }
    end

    def shop_dates_overlap(policy_to_check, employer, policy_start, policy_end)

    end

    def ivl_dates_overlap(coverage_start, coverage_end, other_start, other_end)

    end
  end
end
