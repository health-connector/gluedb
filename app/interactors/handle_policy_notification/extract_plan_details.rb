module HandlePolicyNotification
  class ExtractPlanDetails
    include Interactor

    # Context Requires:
    # - policy_cv (Openhbx::Cv2::Policy)
    # Context Outputs:
    # - plan_details (HandlePolicyNotification::PlanDetails)
    def call
      policy_cv = context.policy_cv
      plan_details = ::HandlePolicyNotification::PlanDetails.new({
        :hios_id => extract_hios_id(policy_cv),
        :active_year => extract_active_year(policy_cv),
      })
      context.plan_details = plan_details
    end

    protected

    def extract_hios_id(policy_cv)
      return nil if policy_cv.policy_enrollment.plan.id.blank?
      policy_cv.policy_enrollment.plan.id.split("#").last
    end

    def extract_active_year(policy_cv)
      return nil if policy_cv.policy_enrollment.plan.blank?
      policy_cv.policy_enrollment.plan.active_year
    end
  end
end
