module HandlePolicyNotification
  # Create or update the 'main' policy in glue to bring the data
  # into line with the changes we are about to transmit.
  class CreatePolicyOrUpdateContinuation
    include Interactor

    # Context requires:
    # - policy_to_create
    # - continuation_policy_action (either a HandlePolicyNotification::PolicyAction or nil)
    def call
    end
  end
end
