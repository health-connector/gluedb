module HandlePolicyNotification
  # Transmit the policy changes.
  # Note that this only applies to the policies with which we are
  # interacting, not the 'main' policy which we may be creating or
  # updating.
  class EmitOtherPolicyOperations
    include Interactor

    # Context requires:
    # - other_policy_actions (array of HandlePolicyNotification::PolicyAction)
    def call
    end
  end
end
