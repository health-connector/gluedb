module HandleEnrollmentEvent
  class VerifyInitialEnrollmentDetails
    include Interactor
    # Context Requires:
    # - policy_details (HandleEnrollmentEvent::PolicyDetails)
    # - plan_details (HandleEnrollmentEvent::PlanDetails)
    # - member_detail_collection (array of HandleEnrollmentEvent::MemberDetails)
    # - employer_details (HandleEnrollmentEvent::EmployerDetails may be nil)
    # - broker_details (HandleEnrollmentEvent::EmployerDetails may be nil)
    # - processing_errors (HandleEnrollmentEvent::ProcessingErrors)
    #
    # Call "fail!" if validation does not pass.

    def parse_market(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      policy_cv.policy_enrollment.shop_market.present? ? "shop" : "individual"
    end

    def parse_enrollment_group_id(policy_cv)
      return nil if policy_cv.id.blank?
      policy_cv.id.split("#").last
    end

    def parse_pre_amt_tot(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      policy_cv.policy_enrollment.premium_total_amount
    end

    def parse_tot_res_amt(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      policy_cv.policy_enrollment.total_responsible_amount
    end

    def parse_tot_emp_res_amt(policy_cv)
      return nil if policy_cv.policy_enrollment.blank?
      return nil if policy_cv.policy_enrollment.shop_market.blank?
      policy_cv.policy_enrollment.shop_market.total_employer_responsible_amount
    end

    def call
      policy_cv = context.policy_cv
      if parse_market(policy_cv).nil?
        context.processing_errors.errors.add(:policy_details, "No market found")
      end

      if parse_enrollment_group_id(policy_cv).nil?
        context.processing_errors.errors.add(:policy_details, "No Enrollment Group ID was submitted.")
      end

      if parse_pre_amt_tot(policy_cv).nil? || parse_tot_res_amt(policy_cv).nil?
        context.processing_errors.errors.add(:policy_details, "One ore more pieces of premium data was not included.")
      end

      if context.plan_details.found_plan.nil?
        context.processing_errors.errors.add(
           :plan_details,
           "No plan found with HIOS ID #{plan_details.hios_id} and active year #{plan_details.active_year}"
        )
      end

      if context.plan_details.found_plan.year >= 2017 && context.plan_details.found_plan.market_type != context.policy_details.market
       context.processing_errors.errors.add(:plan_details, "Plan submitted doesn't match the market.")
      end

      existing_subscriber = context.member_detail_collection.detect do |md|
        md.is_subscriber
      end

      if existing_subscriber.nil?
        context.processing_errors.errors.add(
          :member_details,
          "there is not a subscriber specified"
        )
      end

      context.member_detail_collection.each do |member_details|
        if member_details.found_member.blank?
          context.processing_errors.errors.add( :member_details, "No member found with hbx id #{member_details.member_id}")
        end
        if member_details.begin_date.blank?
          context.processing_errors.errors.add( :member_details, "hbx id #{member_details.member_id} does not have a coverage start date")
        end
      end

      if context.broker_details && context.broker_details.found_broker.blank?
        context.processing_errors.errors.add( :broker_details, "No broker found with npn #{context.broker_details.npn}")
      end

      if context.policy_details.market == "shop" && context.employer_details.found_employer.blank?
        context.processing_errors.errors.add( :employer_details, "No employer found with fein #{context.employer_details.fein}")
      end

      if context.policy_details.market == "shop"
        context.processing_errors.errors.add( :market_type, "we don't support shop yet" )
      end

      if context.processing_errors.has_errors?
        context.fail!
      end
    end
  end
end
