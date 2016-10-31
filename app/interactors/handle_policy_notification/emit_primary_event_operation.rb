module HandlePolicyNotification
  # Transmit the policy operation for the 'main' policy.
  class EmitPrimaryEventOperation
    include Interactor

    # Context requires:
    # - primary_policy_action (a HandlePolicyNotification::PolicyAction)
    def call
    end
  end
end
