module HandlePolicyNotification
  class ProcessNotification
    include Interactor::Organizer

    organize(
      ::HandlePolicyNotification::ExtractPolicyDetails,
      ::HandlePolicyNotification::ExtractMemberDetails,
      ::HandlePolicyNotification::FindExistingPolicy,
      ::HandlePolicyNotification::FindInteractingPolicies
    )
  end
end
