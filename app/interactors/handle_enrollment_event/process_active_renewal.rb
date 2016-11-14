module HandleEnrollmentEvent
  class ProcessActiveRenewal
    include Interactor::Organizer

    organize(
      HandleEnrollmentEvent::ExtractPolicyDetails,
      HandleEnrollmentEvent::ExtractPlanDetails,
      HandleEnrollmentEvent::ExtractEmployerDetails,
      HandleEnrollmentEvent::ExtractMemberDetails,
      HandleEnrollmentEvent::VerifyActiveRenewalDetails,
      HandleEnrollmentEvent::CreateNewMembers,
      HandleEnrollmentEvent::CreateNewPolicy,
      HandleEnrollmentEvent::TransmitNewShopPolicy,
      HandleEnrollmentEvent::TransformAndEmitVocabulary
    )
  end
end
