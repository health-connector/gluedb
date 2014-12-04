class Api::V2::RenewalPoliciesController < ApplicationController

  def show
    @policy = Policy.find(params[:id])

    member_repo = Caches::MemberCache.new(@policy.enrollees.map(&:m_id))
    calc = Premiums::PolicyCalculator.new(member_repo)

    if @policy.is_shop?
      start_date = @policy.employer.renewal_plan_year_of(@policy.subscriber.coverage_start).start_date
    else
      start_date = Date.new(@policy.subscriber.coverage_start.year + 1,1,1)
    end

    @renewal = @policy.clone_for_renewal(start_date)
    calc.apply_calculations(@renewal)

    Caches::MongoidCache.with_cache_for(Carrier) do
      render 'show'
    end
  end
end
