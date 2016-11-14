module HandleEnrollmentEvent
  # Extract the changes to make to the members
  class ExtractMemberChanges
    include Interactor

    # Context Requires:
    # - enrollment_event_cv (Openhbx::Cv2::EnrollmentEvent)
    # Context Outputs:
    # - member_changes_collection (Array of HandleEnrollmentEvent::MemberChange)
    def call
    end
  end
end
