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
        if !continuation_policy.nil?
          # 'Active' renewal
          context.processing_errors.errors.add(:event_kind, "right now we only handle passive renewals, this looks like an active renewal")
          fail!
        else
          # 'Passive' renewal
          primary_policy_action = build_passive_renewal_on(
             context.policy_details,
             context.member_detail_collection,
             context.plan_details,
             context.broker_details,
             context.employer_details)
        end
      elsif context.interacting_policies.empty? && context.renewal_policies.empty?
          primary_policy_action = build_initial_enrollment_on(
             context.policy_details,
             context.member_detail_collection,
             context.plan_details,
             context.broker_details,
             context.employer_details)
      elsif context.interacting_policies.any? && context.renewal_policies.empty?
        # Plan change, add, or remove
        context.processing_errors.errors.add(:event_kind, "right now we only handle passive renewals, this looks like a change")
        context.fail!
      elsif context.interacting_policies.any? && context.renewal_policies.any?
        # Either plan change, add, or 'active' renewal
        context.processing_errors.errors.add(:event_kind, "right now we only handle passive renewals, this looks like a change with possible renewals")
        context.fail!
      end
      context.primary_policy_action = primary_policy_action
      context.other_policy_actions = other_policy_actions
    end

    def build_initial_enrollment_on(policy_details, member_detail_collection, plan_details, broker_details, employer_details)
      member_changes = build_member_changes(member_detail_collection)
      HandlePolicyNotification::PolicyAction.new({
        :action => "initial",
        :policy_details => policy_details,
        :member_changes => member_changes,
        :plan_details => plan_details,
        :broker_details => broker_details,
        :employer_details => employer_details
      })
    end

    def build_passive_renewal_on(policy_details, member_detail_collection, plan_details, broker_details,employer_details)
      member_changes = build_member_changes(member_detail_collection)
      HandlePolicyNotification::PolicyAction.new({
        :action => "renew",
        :policy_details => policy_details,
        :member_changes => member_changes,
        :plan_details => plan_details,
        :broker_details => broker_details,
        :employer_details => employer_details
      })
    end

    def build_member_changes(member_detail_collection)
      member_detail_collection.map do |md|
        HandlePolicyNotification::MemberChange.new({
          :member_id => md.member_id
        })
      end
    end
  end
end
