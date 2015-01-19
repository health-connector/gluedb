module Generators::Reports  
  class IrsInputBuilder

    attr_reader :notice

    def initialize(policy)
      @policy = policy
      @notice = PdfTemplates::IrsNoticeInput.new
      @subscriber = @policy.subscriber.person
      @notice.issuer_name = @policy.plan.carrier.name
      @notice.policy_id = @policy.eg_id
      append_recipient_address
      append_household
      append_monthly_premiums 
    end

    def append_recipient_address
      primary_address = @subscriber.addresses[0]
      @notice.recipient_address = PdfTemplates::NoticeAddress.new({
        street_1: primary_address.address_1,
        street_2: primary_address.address_2,
        city: primary_address.city,
        state: primary_address.state,
        zip: primary_address.zip
      })
    end

    def append_household
      @notice.recipient = build_enrollee_ele(@policy.subscriber)
      spouse = @policy.enrollees_sans_subscriber.detect { |m| m.relationship_status_code.downcase == "spouse" }
      @notice.spouse = build_enrollee_ele(spouse) if spouse
      # enrollees = @policy.enrollees_sans_subscriber.reject { |m| m.relationship_status_code.downcase == "spouse" } 
      @notice.covered_household = @policy.enrollees.map{|enrollee| build_enrollee_ele(enrollee)}
    end

    def build_enrollee_ele(enrollee)
      individual = enrollee.person
      authority_member = individual.authority_member

      PdfTemplates::Enrolee.new({
        name: individual.full_name,
        # ssn: authority_member.ssn,
        ssn: '000000000',
        dob: (authority_member.dob.blank? ? nil : authority_member.dob.strftime("%m/%d/%Y")),
        subscriber: (enrollee.relationship_status_code.downcase == 'self' ? true : false),
        spouse: (enrollee.relationship_status_code.downcase == 'spouse' ? true : false),
        coverage_start_date: (enrollee.coverage_start.blank? ? nil : enrollee.coverage_start.strftime("%m/%d/%Y")),
        coverage_termination_date: (enrollee.coverage_end.blank? ? nil : enrollee.coverage_end.strftime("%m/%d/%Y"))
        })
    end

    def append_monthly_premiums
      @notice.monthly_premiums = (1..12).inject([]) do |data, i|
        data << PdfTemplates::MonthlyPremium.new({
          serial: i,
          premium_amount: @policy.pre_amt_tot,
          premium_amount_slcsp: silver_plan_premium,
          monthly_aptc: ''
        })
      end
    end

    def silver_plan_premium
      calc = Premiums::PolicyCalculator.new
      silver_plan = Plan.where({ "year" => 2014, "hios_plan_id" => "86052DC0400001-01" }).first
      clone_pol = @policy.clone_with_plan(silver_plan)
      calc.apply_calculations(clone_pol)
      clone_pol.pre_amt_tot
    end
  end
end