module HandlePolicyNotification
  class VerifyRequiredDetailsPresent
    # Context Requires:
    # - policy_details (Openhbx::Cv2::Policy)
    # - plan_details (HandlePolicyNotification::PlanDetails)
    # - member_detail_collection (array of HandlePolicyNotification::MemberDetails)
    # -  (HandlePolicyNotification::BrokerDetails may be nil)
    # - empbroker_detailsloyer_details (HandlePolicyNotification::EmployerDetails may be nil)
    # - processing_errors (HandlePolicyNotification::ProcessingErrors)
    #
    # Call "fail!" if validation does not pass.
    def call
      if policy_details.market.blank?
        context.processing_errors.errors.add(:policy_details, "No market found")
      end
      if policy_details.enrollment_group_id.blank?
        context.processing_errors.errors.add(:policy_details, "No Enrollment Group ID was submitted.")
      end
      if policy_details.pre_amt_tot.blank? || policy_details.tot_res_amt.blank? || policy_details.tot_emp_res_amt.blank?
        context.processing_errors.errors.add(:policy_details, "One ore more pieces of premium data was not included."
      end

      if plan_details.found_plan.nil?
        context.processing_errors.errors.add(
           :plan_details,
           "No plan found with HIOS ID #{plan_details.hios_id} and active year #{plan_details.active_year}"
        )
      end

      member_details_collection.each do |member_details|
        if member_details.found_member.blank?
          processing_errors.errors.add( :member_details, "No member found with hbx id #{member_details.member_id}")
        end
      end

      if broker_details.found_broker.blank?
        processing_errors.errors.add( :broker_details, "No broker found with npn #{broker_details.npn}"
      end

      if employer_details.found_employer.blank?
        processing_errors.errors.add( :employer_details, "No employer found with fein #{employer_details.fein}")
      end

      if processing_errors.has_errors?
        fail!
      end
    end
  end
end
