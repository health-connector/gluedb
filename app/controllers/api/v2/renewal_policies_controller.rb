class Api::V2::RenewalPoliciesController < ApplicationController

  def show
    @policy = Policy.find(params[:id])

    member_repo = Caches::MemberCache.new(@policy.enrollees.map(&:m_id))
    calc = Premiums::PolicyCalculator.new(member_repo)

    if @policy.is_shop?
      start_date = Date.current.next_year
    else
      start_date = Date.current.next_year
    end

    @renewal = @policy.clone_for_renewal(start_date)
    calc.apply_calculations(@renewal)
  end
end
