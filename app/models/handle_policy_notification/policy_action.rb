module HandlePolicyNotification
  class PolicyAction
    include Virtus.model

    # If we have both a target policy and policy details,
    # it's an update.
    # If we have just policy details, it's a create
    attribute :action, String
    attribute :target_policy, Policy
    attribute :policy_details, ::HandlePolicyNotification::PolicyDetails
    attribute :employer_details, ::HandlePolicyNotification::EmployerDetails
    attribute :broker_details, ::HandlePolicyNotification::BrokerDetails
    attribute :plan_details, ::HandlePolicyNotification::PlanDetails
    attribute :member_changes, Array[::HandlePolicyNotification::MemberChange]
  end
end
