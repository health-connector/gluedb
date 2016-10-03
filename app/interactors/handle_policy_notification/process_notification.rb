module HandlePolicyNotification
  class ProcessNotification
    include Interactor::Organizer

    organize(
      ::HandlePolicyNotification::ExtractPolicyDetails,
      ::HandlePolicyNotification::FindExistingPolicy,
      ::HandlePolicyNotification::ExtractMemberDetails
    )
  end
end
