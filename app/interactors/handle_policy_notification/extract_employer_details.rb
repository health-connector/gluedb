module HandlePolicyNotification
  class ExtractEmployerDetails
    include Interactor

    # Context Requires:
    # - policy_cv (Openhbx::Cv2::Policy)
    # Context Outputs:
    # - employer_details (HandlePolicyNotification::EmployerDetails may be nil)
    def call
    end
  end
end
