module HandleEnrollmentEvent
  # Send the updated action to NFP if it is shop
  class TransmitShopChange
    include Interactor

    # Context Requires:
    # - policy_details (HandleEnrollmentEvent::PolicyDetails may be nil)
    # - enrollment_event_cv (Openhbx::Cv2::EnrollmentEvent)
    # - member_changes_collection (array HandleEnrollmentEvent::MemberChange)
    # - glue_policy (Policy)
    def call
    end
  end
end
