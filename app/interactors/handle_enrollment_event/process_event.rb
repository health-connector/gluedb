module HandleEnrollmentEvent
  class ProcessEvent
    include Interactor::Organizer

    organize(
      ::HandleEnrollmentEvent::ExtractEventDetails,
      ::HandleEnrollmentEvent::ExtractPolicyDetails,
      ::HandleEnrollmentEvent::ExtractMemberDetails,
      ::HandleEnrollmentEvent::CreateOrUpdatePolicy,
      ::HandleEnrollmentEvent::TransformAndEmitVocabulary
    )
  end
end
