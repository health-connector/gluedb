class Api::V2::RenewalPoliciesController < ApplicationController
  def index
    clean_eg_id = Regexp.new(Regexp.escape(params[:enrollment_group_id].to_s))

    search = {"eg_id" => clean_eg_id}
    if(!params[:ids].nil? && !params[:ids].empty?)
      search['_id'] = {"$in" => params[:ids]}
    end

    @policies = Policy.where(search)

    page_number = params[:page]
    page_number ||= 1
    @policies = @policies.page(page_number).per(20)

    Caches::MongoidCache.with_cache_for(Carrier) do
      render "index"
    end
  end

  def show
    @policy = Policy.find(params[:id])

    m_ids = @policy.enrollees.map(&:m_id)
    member_repo = Caches::MemberCache.new(m_ids)
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
