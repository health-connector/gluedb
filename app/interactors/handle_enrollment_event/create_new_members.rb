module HandleEnrollmentEvent
  # Create any members which don't already exist in glue.
  class CreateNewMembers
    include Interactor

    # Context Requires:
    # - member_detail_collection (array of HandleEnrollmentEvent::MemberDetails)
    def call
    end

  end
end
