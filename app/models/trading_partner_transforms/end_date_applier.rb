module TradingPartnerTransforms
  # Applies the selected data preparation action to each policy in the
  # request before transforms are generated. The remove and change actions
  # mirror the migrations rake tasks remove_policy_end_date and
  # change_policy_end_date. The rake task files are left untouched on purpose.
  # Every applied change is logged with the acting user and ticket number.
  class EndDateApplier

    def initialize(transform_request, user_email)
      @transform_request = transform_request
      @user_email = user_email
    end

    def apply!
      return unless @transform_request.end_date_action_selected?
      @transform_request.policies.each do |policy|
        apply_to_policy(policy)
        log_action(policy)
        policy.reload
      end
    end

    protected

    def apply_to_policy(policy)
      case @transform_request.end_date_action
      when "change"
        change_end_date(policy, @transform_request.effective_end_date_for(policy))
      when "remove"
        remove_end_date(policy, @transform_request.aasm_state, @transform_request.benefit_status)
      when "remove_cobra"
        remove_cobra_date(policy)
      end
    end

    # Same behavior as the migrations change_policy_end_date rake task.
    # The policy is canceled when the end date equals the policy start
    # and terminated otherwise.
    def change_end_date(policy, end_date)
      policy.enrollees.each do |enrollee|
        enrollee.emp_stat = "terminated"
        enrollee.coverage_status = "inactive"
        enrollee.coverage_end = end_date
        enrollee.save!
      end
      policy.aasm_state = policy.policy_start == end_date ? "canceled" : "terminated"
      policy.save!
    end

    # Same behavior as the migrations remove_policy_end_date rake task.
    def remove_end_date(policy, aasm_state, benefit_status)
      policy.enrollees.each do |enrollee|
        enrollee.ben_stat = benefit_status
        enrollee.emp_stat = "active"
        enrollee.coverage_status = "active"
        enrollee.coverage_end = nil
        enrollee.save!
      end
      policy.aasm_state = aasm_state
      policy.save!
    end

    # There is no rake task for this fix. Ops normally unsets the cobra
    # eligibility date in a console session.
    def remove_cobra_date(policy)
      policy.unset(:cobra_eligibility_date)
    end

    def log_action(policy)
      details = case @transform_request.end_date_action
                when "change"
                  "end_date=#{@transform_request.effective_end_date_for(policy).strftime('%m/%d/%Y')} mode=#{@transform_request.change_mode}"
                when "remove"
                  "aasm_state=#{@transform_request.aasm_state} benefit_status=#{@transform_request.benefit_status}"
                else
                  "cobra_eligibility_date unset"
                end
      ticket = @transform_request.ticket_number.presence || "none"
      Rails.logger.info(
        "[TradingPartnerTransforms] user=#{@user_email} ticket=#{ticket} " \
        "action=#{@transform_request.end_date_action} eg_id=#{policy.eg_id} #{details}"
      )
    end
  end
end
