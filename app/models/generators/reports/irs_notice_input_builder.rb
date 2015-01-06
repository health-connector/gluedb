module Generators::Reports  
  class IrsNoticeInputBuilder

    attr_reader :notice

    def initialize(policy)
      @policy = policy
      @notice = PdfTemplates::IrsNoticeInput.new
      @subscriber = @policy.subscriber.person

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
      @notice.spouse = build_enrollee_ele(spouse)
      enrollees = @policy.enrollees_sans_subscriber.reject { |m| m.relationship_status_code.downcase == "spouse" } 
      @notice.covered_household = enrollees.map{|enrollee| build_enrollee_ele(enrollee)}
    end

    def append_monthly_premiums
    end


    def build_enrollee_ele(enrollee)
      individual = enrollee.person
      authority_member = individual.authority_member

      PdfTemplates::Enrolee.new({
        name: individual.full_name,
        ssn: authority_member.ssn,
        dob: (authority_member.dob.blank? ? nil : authority_member.dob.strftime("%m/%d/%Y")),
        subscriber: (enrollee.relationship_status_code.downcase == 'self' ? true : false),
        spouse: (enrollee.relationship_status_code.downcase == 'spouse' ? true : false),
        coverage_start_date: (enrollee.coverage_start.blank? ? nil : enrollee.coverage_start.strftime("%m/%d/%Y")),
        coverage_termination_date: (enrollee.coverage_end.blank? ? nil : enrollee.coverage_end.strftime("%m/%d/%Y"))
        })
    end
  end
end