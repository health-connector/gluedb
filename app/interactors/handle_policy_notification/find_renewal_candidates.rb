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
      possible_renewals = []
      subscriber_member_details = context.member_detail_collection.detect { |md| md.is_subscriber }
      subscriber_person = Person.where("members.hbx_member_id" => subscriber_member_details.member_id).first
      coverage_start = subscriber_member_details.begin_date
      if context.policy_details.market != "shop"
        if (coverage_start.day == 1) && (coverage_start.month == 1)
           possible_renewals = subscriber_person.policies.select do |pol|
             is_an_ivl_renewal_compared_to(pol, context.plan_details.found_plan, coverage_start)
           end
        end
      end
      context.renewal_policies = possible_renewals
    end

    def is_an_ivl_renewal_compared_to(pol, plan, coverage_start)
      return false unless pol.policy_end.blank?
      return false unless (coverage_start.year - pol.policy_start.year ) == 1
      return false if (pol.plan.market_type == "shop")
      (plan.carrier_id == pol.plan.carrier_id) && (plan.coverage_type == pol.plan.coverage_type)
    end
  end
end
