module HandlePolicyNotification
  class ExtractEmployerDetails
    include Interactor

    # Context Requires:
    # - policy_cv (Openhbx::Cv2::Policy)
    # Context Outputs:
    # - employer_details (HandlePolicyNotification::EmployerDetails may be nil)
    def call
      policy_enrollment = context.policy_cv.policy_enrollment
      return nil if policy_enrollment.blank?
      shop_market = policy_enrollment.shop_market
      return nil if shop_market.blank?
      employer_link = shop_market.employer_link
      return nil if shop_market.employer_link.blank?
      employer_id = employer_link.id
      return nil if employer_id.blank?
      fein = employer_id.strip.split("#").last
      return nil if fein.blank?
      HandlePolicyNotification::EmployerDetails.new({
        :fein => fein
      })
    end
  end
end
