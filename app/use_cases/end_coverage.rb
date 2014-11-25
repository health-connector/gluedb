class EndCoverage
  def initialize(action_factory, policy_repo = Policy)
    @policy_repo = policy_repo
    @action_factory = action_factory
  end

  def execute(request)
    @request = request
    affected_enrollee_ids = @request[:affected_enrollee_ids]
    return if affected_enrollee_ids.empty?

    @policy = @policy_repo.find(request[:policy_id])

    enrollees_not_already_canceled = @policy.enrollees.select { |e| !e.canceled? }

    update_policy(affected_enrollee_ids)

    action = @action_factory.create_for(request)
    action_request = {
      policy_id: @policy.id,
      operation: request[:operation],
      reason: request[:reason],
      affected_enrollee_ids: request[:affected_enrollee_ids],
      include_enrollee_ids: enrollees_not_already_canceled.map(&:m_id),
      current_user: request[:current_user]
    }
    action.execute(action_request)
  end

  def execute_csv(request, listener)
    @request = request
    @policy = @policy_repo.where({"_id" => request[:policy_id]}).first

    if (@policy.nil?)
      listener.no_such_policy(policy_id: request[:policy_id])
      listener.fail
      return
    end

    affected_enrollee_ids = @request[:affected_enrollee_ids]

    if (affected_enrollee_ids.nil?)
      listener.fail(subscriber: request[:affected_enrollee_ids])
      return
    end

    if @policy.subscriber.coverage_ended?
      listener.policy_inactive(policy_id: request[:policy_id])
      listener.fail(subscriber: request[:affected_enrollee_ids])
      return
    end

    if @policy.enrollees.any?{ |e| e.coverage_start > request[:coverage_end].to_date }
      listener.end_date_invalid(end_date: request[:coverage_end])
      listener.fail(subscriber: request[:affected_enrollee_ids])
      return
    end

    enrollees_not_already_canceltermed= @policy.enrollees.select { |e| !e.canceled? && !e.terminated? }

    update_policy(affected_enrollee_ids)

    action = @action_factory.create_for(request)

    action_request = {
      policy_id: @policy.id,
      operation: request[:operation],
      reason: request[:reason],
      affected_enrollee_ids: request[:affected_enrollee_ids],
      include_enrollee_ids: enrollees_not_already_canceltermed.map(&:m_id),
      current_user: request[:current_user]
    }
    action.execute(action_request)
    listener.success(subscriber: request[:affected_enrollee_ids])
  end

  private

  def update_policy(affected_enrollee_ids)
    subscriber = @policy.subscriber
    employer_contribution_percentage = @policy.employer_contribution / @policy.total_premium_amount

    if(affected_enrollee_ids.include?(subscriber.m_id))
      end_coverage_for_everyone
    else
      end_coverage_for_ids(affected_enrollee_ids)
    end

    @policy.total_responsible_amount = @policy.total_premium_amount - total_credit_adjustment(employer_contribution_percentage)

    @policy.updated_by = @request[:current_user]
    @policy.save
  end

  def total_credit_adjustment(percent)
    @policy.employer_contribution = (@policy.total_premium_amount * percent).truncate(2)
  end

  def end_coverage_for_everyone
    select_active(@policy.enrollees).each do |enrollee|
      end_coverage_for(enrollee, @request[:coverage_end])
    end

    @policy.total_premium_amount = final_premium_total
  end

  def end_coverage_for_ids(ids)
    enrollees = ids.map { |id| @policy.enrollee_for_member_id(id) }
    select_active(enrollees).each do |enrollee|
      end_coverage_for(enrollee, @request[:coverage_end])

      @policy.total_premium_amount -= enrollee.pre_amt
    end
  end

  def select_active(enrollees)
    enrollees.select { |e| e.coverage_status == 'active' }
  end

  def final_premium_total
    new_premium_total = 0
    if(@request[:operation] == 'cancel')
      @policy.enrollees.each { |e| new_premium_total += e.pre_amt }
    elsif(@request[:operation] == 'terminate')
      @policy.enrollees.each do |e|
        new_premium_total += e.pre_amt if e.coverage_end == @policy.subscriber.coverage_end
      end
    end
    new_premium_total
  end

  def end_coverage_for(enrollee, date)
    enrollee.coverage_status = 'inactive'

    if(@request[:operation] == 'cancel')
      enrollee.coverage_end = enrollee.coverage_start
    else
      enrollee.coverage_end = date
    end
  end
end
