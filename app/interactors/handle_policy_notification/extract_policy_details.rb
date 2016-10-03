module HandlePolicyNotification
  class ExtractPolicyDetails
    include Interactor

    def call
      policy_cv = context.policy_cv
      policy_details = OpenStruct.new({
        :enrollment_group_id => parse_enrollment_group_id(policy_cv)
      })
      context.policy_details = policy_details
    end

    protected

    def parse_enrollment_group_id(policy_cv)
      return nil if policy_cv.id.blank?
      policy_cv.id.split("#").last
    end
  end
end
