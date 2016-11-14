module HandleEnrollmentEvent
  class ProcessAutoRenew
    include Interactor::Organizer

    organize(
      HandleEnrollmentEvent::ExtractPolicyDetails,
      HandleEnrollmentEvent::ExtractPlanDetails,
      HandleEnrollmentEvent::ExtractEmployerDetails,
      HandleEnrollmentEvent::ExtractMemberDetails,
      HandleEnrollmentEvent::VerifyPassiveRenewalDetails,
      HandleEnrollmentEvent::CreateNewMembers,
      HandleEnrollmentEvent::CreateNewPolicy,
      HandleEnrollmentEvent::TransmitNewShopPolicy,
      HandleEnrollmentEvent::TransformAndEmitVocabulary
    )
  end
end
