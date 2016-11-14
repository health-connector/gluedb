module HandleEnrollmentEvent
  class ProcessInitialEnrollment
    include Interactor::Organizer

    organize(
      HandleEnrollmentEvent::ExtractPolicyDetails,
      HandleEnrollmentEvent::ExtractPlanDetails,
      HandleEnrollmentEvent::ExtractEmployerDetails,
      HandleEnrollmentEvent::ExtractMemberDetails,
      HandleEnrollmentEvent::VerifyRequiredDetailsPresent,
      HandleEnrollmentEvent::CreateNewMembers,
      HandleEnrollmentEvent::CreateNewPolicy,
      HandleEnrollmentEvent::TransmitShopPolicy,
      HandleEnrollmentEvent::TransformAndEmitVocabulary
    )
  end
end
