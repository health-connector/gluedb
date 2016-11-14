module HandleEnrollmentEvent
  class ProcessDependentDrop
    include Interactor::Organizer

    organize(
      HandleEnrollmentEvent::ExtractPolicyDetails,
      HandleEnrollmentEvent::ExtractMemberChanges,
      HandleEnrollmentEvent::VerifyDependentAddDetails,
      HandleEnrollmentEvent::UpdatePolicy,
      HandleEnrollmentEvent::TransmitShopChange,
      HandleEnrollmentEvent::TransformAndEmitVocabulary
    )
  end
end
