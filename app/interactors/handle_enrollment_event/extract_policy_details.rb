module HandleEnrollmentEvent
  class ExtractPolicyDetails
    include Interactor

    # Context Requires:
    # - enrollment_event_cv (OpenHbx::Cv2::EnrollmentEvent)
    # Context Outputs:
    # - policy_details (HandlePolicyNotification::PolicyDetails)
    # - policy_cv (Openhbx::Cv2::Policy, might be nil if xml is structured wrong)
    def call
      policy_cv = extract_policy_cv(context.enrollment_event_cv)
      context.policy_cv = policy_cv
      policy_details = ::HandleEnrollmentEvent::PolicyDetails.new({
        :enrollment_group_id => parse_enrollment_group_id(policy_cv),
        :pre_amt_tot => parse_pre_amt_tot(policy_cv),
        :tot_res_amt => parse_tot_res_amt(policy_cv),
        :tot_emp_res_amt => parse_tot_emp_res_amt(policy_cv),
        :market => parse_market(policy_cv)
      })
      context.policy_details = policy_details
    end

    protected

    def extract_policy_cv(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.enrollment.policy.value
    end

    def parse_enrollment_group_id(policy_cv)
      return nil if policy_cv.nil?
      return nil if policy_cv.id.blank?
      policy_cv.id.split("#").last
    end

    def parse_market(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      policy_cv.policy_enrollment.shop_market.present? ? "shop" : "individual"
    end

    def parse_pre_amt_tot(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      policy_cv.policy_enrollment.premium_total_amount
    end

    def parse_tot_res_amt(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      policy_cv.policy_enrollment.total_responsible_amount
    end

    def parse_tot_emp_res_amt(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      return nil if policy_cv.policy_enrollment.shop_market.blank?
      policy_cv.policy_enrollment.shop_market.total_employer_responsible_amount
    end
  end
end
