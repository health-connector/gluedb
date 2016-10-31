module HandlePolicyNotification
  # We need to consider three factors here to arrive out our decision:
  # - New Policy, or Continuation Policy?
  # - If a continuation policy exists, what has changed about it?
  # - What are the dispositions of the other interacting policies that would
  #   affect the action we should take, and what should we do to those policies?
  # - Is there a potential policy that would make this behave as a 
  class DeterminePolicyActions
    include Interactor

    # Context requires:
    # - continuation_policy (either a Policy or nil)
    # - member_detail_collection (array of HandlePolicyNotification::MemberDetails)
    # - interacting_policies (array of Policy)
    # - renewal_policies (array of Policy)
    # Context outputs:
    # - primary_policy_action (a HandlePolicyNotification::PolicyAction)
    # - other_policy_actions (array of HandlePolicyNotification::PolicyAction)
    def call
      other_policy_actions = []
      primary_policy_action = nil
      if context.interacting_policies.empty? && context.renewal_policies.any?
        # 'Passive' renewal
      elsif context.interacting_policies.empty? && context.renewal_policies.empty?
        # Plan change, add, or remove
        processing_errors.errors.add(:event_kind, "right now we only handle passive renewals")
        fail!
      elsif context.interacting_policies.any? && context.renewal_policies.empty?
        # Plan change, add, or remove
        processing_errors.errors.add(:event_kind, "right now we only handle passive renewals")
        fail!
      elsif context.interacting_policies.any? && context.renewal_policies.any?
        # Either plan change, add, or 'active' renewal
        processing_errors.errors.add(:event_kind, "right now we only handle passive renewals")
        fail!
      end
      context.primary_policy_action = primary_policy_action
      context.other_policy_actions = other_policy_actions
    end
  end
end
