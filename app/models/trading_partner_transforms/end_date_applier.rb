module TradingPartnerTransforms
  # Applies the selected data preparation action to each policy and logs
  # each change with the user and ticket number.
  class EndDateApplier

    attr_reader :applied_eg_ids, :failures

    def initialize(transform_request, user_email)
      @transform_request = transform_request
      @user_email = user_email
      @applied_eg_ids = []
      @failures = []
    end

    # Each policy is saved on its own. A failure on one policy is added to
    # failures as [eg_id, message] and the rest continue.
    def apply!
      return unless @transform_request.end_date_action_selected?
      @transform_request.policies.each do |policy|
        begin
          apply_to_policy(policy)
          @applied_eg_ids << policy.eg_id
          log_action(policy)
        rescue StandardError => e
          @failures << [policy.eg_id, e.message]
          Rails.logger.error("[TradingPartnerTransforms] user=#{@user_email} ticket=#{ticket_label} action=#{@transform_request.end_date_action} eg_id=#{policy.eg_id} failed: #{e.message}")
        end
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

    # Ends coverage for every enrollee. The policy is canceled when the end
    # date equals the policy start, terminated otherwise.
    def change_end_date(policy, end_date)
      policy.enrollees.each do |enrollee|
        enrollee.emp_stat = "terminated"
        enrollee.coverage_status = "inactive"
        enrollee.coverage_end = end_date
      end
      policy.aasm_state = policy.policy_start == end_date ? "canceled" : "terminated"
      save_policy(policy)
    end

    # Clears enrollee end dates and restores the given policy state and benefit status.
    def remove_end_date(policy, aasm_state, benefit_status)
      policy.enrollees.each do |enrollee|
        enrollee.ben_stat = benefit_status
        enrollee.emp_stat = "active"
        enrollee.coverage_status = "active"
        enrollee.coverage_end = nil
      end
      policy.aasm_state = aasm_state
      save_policy(policy)
    end

    def remove_cobra_date(policy)
      policy.cobra_eligibility_date = nil
      save_policy(policy)
    end

    # One save per policy, so the policy history records the change and
    # the user who made it.
    def save_policy(policy)
      policy.updated_by = @user_email
      policy.save!
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
      Rails.logger.info(
        "[TradingPartnerTransforms] user=#{@user_email} ticket=#{ticket_label} " \
        "action=#{@transform_request.end_date_action} eg_id=#{policy.eg_id} #{details}"
      )
    end

    def ticket_label
      @transform_request.ticket_number.presence || "none"
    end
  end
end
