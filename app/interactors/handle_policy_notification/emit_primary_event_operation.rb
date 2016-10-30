module HandlePolicyNotification
  # Transmit the policy operation for the 'main' policy.
  class EmitPrimaryEventOperation
    include Interactor

    # Context requires:
    # - policy_to_create
    # - continuation_policy_action (either a HandlePolicyNotification::PolicyAction or nil)
    def call
    end
  end
end
