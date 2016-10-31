module HandlePolicyNotification
  class PolicyAction
    include Virtus.model

    # If we have both a target policy and policy details,
    # it's an update.
    # If we have just policy details, it's a create
    attribute :target_policy, Policy
    attribute :policy_details, ::HandlePolicyNotification::PolicyDetails
    attribute :member_change, Array[::HandlePolicyNotification::MemberChanges]
  end
end
