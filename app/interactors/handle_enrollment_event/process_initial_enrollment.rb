module HandleEnrollmentEvent
  class ProcessInitialEnrollment
    include Interactor::Organizer

    organize(
      HandleEnrollmentEvent::ExtractPolicyDetails,
      HandleEnrollmentEvent::ExtractPlanDetails,
      HandleEnrollmentEvent::ExtractEmployerDetails,
      HandleEnrollmentEvent::ExtractMemberDetails,
      HandleEnrollmentEvent::VerifyInitialEnrollmentDetails,
      HandleEnrollmentEvent::CreateNewMembers,
      HandleEnrollmentEvent::CreateNewPolicy,
      HandleEnrollmentEvent::TransmitNewShopPolicy,
      HandleEnrollmentEvent::TransformAndEmitVocabulary
    )
  end
end
