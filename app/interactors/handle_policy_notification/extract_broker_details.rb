module HandlePolicyNotification
  class ExtractBrokerDetails
    include Interactor

    # Context Requires:
    # - policy_cv (Openhbx::Cv2::Policy)
    # Context Outputs:
    # - broker_details (HandlePolicyNotification::BrokerDetails may be nil)
    def call
    end
  end
end
