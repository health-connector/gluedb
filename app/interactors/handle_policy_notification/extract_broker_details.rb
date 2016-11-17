module HandlePolicyNotification
  class ExtractBrokerDetails
    include Interactor

    # Context Requires:
    # - policy_cv (Openhbx::Cv2::Policy)
    # Context Outputs:
    # - broker_details (HandlePolicyNotification::BrokerDetails may be nil)
    def call
      return if context.policy_cv.broker_link.nil?
      broker_link = context.policy_cv.broker_link
      context.broker_details = HandlePolicyNotification::BrokerDetails.new({
         :npn => broker_link.npn_from_id
      })
    end
  end
end
