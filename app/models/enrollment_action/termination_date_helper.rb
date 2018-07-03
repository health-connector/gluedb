module EnrollmentAction
  module TerminationDateHelper
    def select_termination_date
      one_day_before_action = action.subscriber_start - 1.day
      termination_stop_date = termination.subscriber_end
      if (termination.existing_policy.policy_start > one_day_before_action)
        return termination_stop_date
      end
      [one_day_before_action, termination_stop_date].min
    end
  end
end
