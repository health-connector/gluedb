module HandlePolicyNotification
  class VerifyRequiredDetailsPresent
    # Context Requires:
    # - policy_details (Openhbx::Cv2::Policy)
    # - plan_details (HandlePolicyNotification::PlanDetails)
    # - member_detail_collection (array of HandlePolicyNotification::MemberDetails)
    # - processing_errors (HandlePolicyNotification::ProcessingErrors)
    #
    # Call "fail!" if validation does not pass.
    def call
      if plan_details.found_plan.nil?
        processing_errors.errors.add(
           :plan_details,
           "No plan found with HIOS ID #{plan_details.hios_id} and active year #{plan_details.active_year}"
        )
      end

      if processing_errors.has_errors?
        fail!
      end
    end
  end
end
