module HandlePolicyNotification
  # Create or update the 'main' policy in glue to bring the data
  # into line with the changes we are about to transmit.
  class CreatePolicyOrUpdateContinuation
    include Interactor

    # Context requires:
    # - primary_policy_action (a HandlePolicyNotification::PolicyAction)
    def call
    end
  end
end
