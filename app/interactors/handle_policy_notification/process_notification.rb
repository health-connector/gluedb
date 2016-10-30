module HandlePolicyNotification
  class ProcessNotification
    include Interactor::Organizer

    organize(
      ::HandlePolicyNotification::ExtractPolicyDetails,
      ::HandlePolicyNotification::ExtractPlanDetails,
      ::HandlePolicyNotification::ExtractMemberDetails,
      ::HandlePolicyNotification::VerifyRequiredDetailsPresent,
      ::HandlePolicyNotification::FindInteractingPolicies,
      ::HandlePolicyNotification::FindRenewalCandidates,
      ::HandlePolicyNotification::FindContinuationPolicy,
      ::HandlePolicyNotification::DeterminePolicyActions,
      ::HandlePolicyNotification::CreatePolicyOrUpdateContinuation,
      ::HandlePolicyNotification::UpdatePolicies,
      ::HandlePolicyNotification::EmitOtherPolicyOperations,
      ::HandlePolicyNotification::EmitPrimaryEventOperation
    )
  end
end
