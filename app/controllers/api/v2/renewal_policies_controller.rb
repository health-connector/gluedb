class Api::V2::RenewalPoliciesController < ApplicationController

  def index
    clean_eg_id = Regexp.new(Regexp.escape(params[:enrollment_group_id].to_s))

    search = {"eg_id" => clean_eg_id}
    if(!params[:ids].nil? && !params[:ids].empty?)
      search['_id'] = {"$in" => params[:ids]}
    end

    @policies = Policy.where(search)
    @renewals = {}

    m_ids = []

    @policies.each do |mpol|
      mpol.enrollees.each do |en|
        m_ids << en.m_id
      end
    end

    member_repo = Caches::MemberCache.new(m_ids)
    calc = Premiums::PolicyCalculator.new(member_repo)

    @policies.each do |p|
      if p.is_shop?
        start_date = p.employer.renewal_plan_year_of(p.subscriber.coverage_start).start_date
      else
        start_date = Date.new(p.subscriber.coverage_start.year + 1,1,1)
      end

      renewal = p.clone_for_renewal(start_date)

      if p.subscriber.canceled? || p.subscriber.terminated?
        renewal.errors.add(:renewal_policy, 'must be active')
      else
        calc.apply_calculations(renewal)
      end

      @renewals[p] = renewal
    end

    Caches::MongoidCache.with_cache_for(Carrier) do
      render "index"
    end
  end

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

    if @renewal.subscriber.nil?
      @renewal.errors.add(:renewal_policy, 'must be active')
      render :status => 422, :xml => @renewal.errors
    else
      calc.apply_calculations(@renewal)

      Caches::MongoidCache.with_cache_for(Carrier) do
        render 'show'
      end
    end
  end
end
