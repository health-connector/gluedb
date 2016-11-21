module HandlePolicyNotification
  # Make the changes to the policy objects in glue to bring the data
  # into line with the changes we are about to transmit.
  # Note that this only applies to the policies with which we are
  # interacting, not the 'main' policy which we may be creating or
  # updating.
  class UpdatePolicies
    include Interactor

    # Context requires:
    # - other_policy_actions (array of HandlePolicyNotification::PolicyAction)
    def call
    end
  end
end
