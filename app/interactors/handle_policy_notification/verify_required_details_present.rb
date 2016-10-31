module HandlePolicyNotification
  class VerifyRequiredDetailsPresent
    include Interactor
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
      processing_errors = context.processing_errors
      @errors = processing_errors.errors
      policy_cv = context.policy_cv
      if parse_market.nil?
        @errors.add(:policy_details, "No market found")
      end

      if parse_enrollment_group_id(policy_cv).nil?
        @errors.add(:policy_details, "No Enrollment Group ID was submitted.")
      end

      if parse_pre_amt_tot.nil? || parse_tot_res_amt.nil? || parse_tot_emp_res_amt.nil?
        @errors.add(:policy_details, "One ore more pieces of premium data was not included.")
      end

      if plan_details.found_plan.nil?
        @errors.add(
           :plan_details,
           "No plan found with HIOS ID #{plan_details.hios_id} and active year #{plan_details.active_year}"
        )
      end

      if plan_details.found_plan.present? && plan_details.found_plan.try(:year) >= 2017 && plan_details.found_plan.market_type != parse_market
        @errors.add(:plan_details, "Plan submitted doesn't match the market.")
      end

      member_details_collection.each do |member_details|
        if member_details.found_member.blank?
          @errors.add( :member_details, "No member found with hbx id #{member_details.member_id}")
        end
        if member_details.is_subscriber.blank?
          @errors.add( :member_details, "#{member_details.member_id} doesn't have the subscriber/dependent indicator set.")
        end
        if member_details.begin_date.blank?
          @errors.add( :member_details, "hbx id #{member_details.member_id} does not have a begin date")
        end
      end

      if broker_details.found_broker.blank?
        @errors.add( :broker_details, "No broker found with npn #{broker_details.npn}")
      end

      if parse_market == "shop" && employer_details.found_employer.blank?
        @errors.add( :employer_details, "No employer found with fein #{employer_details.fein}")
      end

      if processing_errors.has_errors?
        context.fail!
      end
    end

    def parse_market
      return nil if policy_enrollment.blank?
      policy_enrollment.shop_market.present? ? "shop" : "individual"
    end

    def parse_enrollment_group_id(policy_cv)
      return nil if policy_cv.id.blank?
      policy_cv.id.split("#").last
    end

    def parse_pre_amt_tot
      return nil if policy_enrollment.blank?
      policy_enrollment.premium_total_amount
    end

    def parse_tot_res_amt
      return nil if policy_enrollment.blank?
      policy_enrollment.total_responsible_amount
    end

    def parse_tot_emp_res_amt
      return nil if policy_enrollment.blank?
      return nil if policy_enrollment.shop_market.blank?
      policy_enrollment.shop_market.total_employer_responsible_amount
    end

    def policy_details
      context.policy_cv
    end

    def policy_enrollment
      policy_details.policy_enrollment
    end

    def plan_details
      policy_enrollment.plan
    end

    def broker_details
      policy_details.broker_link
    end

    def member_details_collection
      policy_details.enrollees
    end

    def employer_details
      policy_enrollment.shop_market.employer_link
    end
  end
end
