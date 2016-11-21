module HandleEnrollmentEvent
  # Send the new enrollment to NFP if it is shop
  class TransmitNewShopPolicy
    include Interactor

    # Context Requires:
    # - policy_details (HandleEnrollmentEvent::PolicyDetails may be nil)
    # - glue_policy (Policy)
    def call
    end

  end
end
