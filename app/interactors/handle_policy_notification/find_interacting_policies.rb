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
      subscriber_member_details = context.member_detail_collection.detect { |md| md.is_subscriber }
      subscriber_person = Person.where("members.hbx_member_id" => subscriber_member_details.member_id).first
      coverage_start = subscriber_member_details.begin_date
      coverage_end = subscriber_member_details.end_date
      possible_matches = []
      if context.policy_details.market == "shop"
        possible_matches = subscriber_person.policies.select do |pol|
          (pol.plan.market_type == "shop") &&
            (pol.plan.coverage_type == context.plan_details.found_plan.coverage_type) &&
            (pol.employer.id == context.employer_details.found_employer.id) &&
            shop_dates_overlap(pol, context.employer_details.found_employer, coverage_start, coverage_end)
        end
      else
        possible_matches = subscriber_person.policies.select do |pol|
          (pol.plan.market_type != "shop") &&
            (pol.plan.coverage_type == context.plan_details.found_plan.coverage_type) &&
            ivl_dates_overlap(coverage_start, coverage_end, pol.policy_start, pol.policy_end)
        end
      end
      context.interacting_policies = possible_matches.reject { |pol| pol.canceled? }
    end

    def shop_dates_overlap(policy_to_check, employer, event_start, event_end)
      return false if policy_to_check.policy_start.nil? || event_start.nil?
      return false if event_start == event_end
      return false if policy_to_check.policy_start == policy_to_check.policy_end
      event_plan_year_start =  employer_plan_year_start(employer, event_start)
      policy_plan_year_start = employer_plan_year_start(employer, policy_to_check.policy_start)
      overlap_date_range(event_start, event_end, policy_to_check.policy_start, policy_to_check.policy_end, event_plan_year_start, policy_plan_year_start)
    end

    def ivl_dates_overlap(event_start, event_end, policy_start, policy_end)
      return false if event_start.nil? || policy_start.nil?
      return false if event_start == event_end
      return false if policy_start == policy_end
      overlap_date_range(event_start, event_end, policy_start, policy_end, event_start.year, policy_start.year)
    end

    def employer_plan_year_start(employer, start_date)
      employer.plan_year_of(start_date).start_date
    end

    def overlap_date_range(event_start, event_end, policy_start, policy_end, event_year, policy_year)
      if event_end.nil? && policy_end.nil?
        event_year == policy_year
      else
        if event_start < policy_start
          if event_end.present?
            event_end >= policy_start
          else
            true
          end
        elsif policy_start < event_start
          if policy_end.present?
            policy_end >= event_start
          else
            true
          end
        else
          true
        end
      end
    end
  end
end
