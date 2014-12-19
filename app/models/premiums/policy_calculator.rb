module Premiums
  class PolicyCalculator
    include MoneyMath

    def initialize(member_cache = nil)
      @member_cache = member_cache
    end

    def apply_calculations(policy)
      apply_premium_rates(policy)
      apply_group_discount(policy)
      apply_totals(policy)
      apply_credits(policy)
    end

    def apply_premium_rates(policy)
      plan = policy.plan
      if policy.is_shop?
        plan_year = determine_shop_plan_year(policy)
        rate_begin_date = plan_year.start_date
        policy.enrollees.each do |en|
          en.pre_amt = calculate_cached_premium(plan, en, rate_begin_date, en.coverage_start)
        end
      else
        policy.enrollees.each do |en|
          en.pre_amt = calculate_cached_premium(plan, en, en.coverage_start, en.coverage_start)
        end
      end
    end

    def calculate_cached_premium(plan, enrollee, rate_start_date, coverage_start)
      member = get_member(enrollee)
      as_dollars(plan.rate(rate_start_date, coverage_start, member.dob).amount)
    end

    def get_member(enrollee)
      return enrollee.member unless @member_cache
      @member_cache.lookup(enrollee.m_id)
    end

    def apply_group_discount(policy)
      children_under_21 = policy.enrollees.select do |en|
        member = get_member(en)
        ager = Ager.new(member.dob)
        age = ager.age_as_of(en.coverage_start)
        (age < 21) && (en.rel_code == "child")
      end
      return(nil) unless children_under_21.length > 3
      orderly_children = (children_under_21.sort_by do |en|
        member = get_member(en)
        ager = Ager.new(member.dob)
        ager.age_as_of(en.coverage_start)
      end).reverse
      orderly_children.drop(3).each do |en|
        en.pre_amt = BigDecimal.new("0.00")
      end
    end

    def apply_totals(policy)
      premium = policy.enrollees.inject(BigDecimal.new("0.00")) do |acc, en|
        as_dollars(acc) + as_dollars(en.pre_amt)
      end
      policy.pre_amt_tot = as_dollars(premium)
    end

    def apply_credits(policy)
      if policy.is_shop?
        plan_year = determine_shop_plan_year(policy)
        contribution_strategy = plan_year.contribution_strategy
        policy.tot_emp_res_amt = as_dollars(contribution_strategy.contribution_for(policy))
        policy.tot_res_amt = as_dollars(policy.pre_amt_tot) - as_dollars(policy.tot_emp_res_amt)
      else
        policy.tot_res_amt = as_dollars(policy.pre_amt_tot) - as_dollars(policy.applied_aptc)
      end
    end

    def get_employer(policy)
      Caches::MongoidCache.lookup(Employer, policy.employer_id) { policy.employer }
    end

    def determine_shop_plan_year(policy)
      coverage_start_date = policy.subscriber.coverage_start
      employer = get_employer(policy)
      employer.plan_year_of(coverage_start_date)
    end

  end
end
