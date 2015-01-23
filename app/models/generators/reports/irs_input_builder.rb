module Generators::Reports  
  class IrsInputBuilder

    attr_reader :notice
 
    IRS_YEAR = 2014

    def initialize(policy)
      @policy = policy
      @policy_disposition = PolicyDisposition.new(policy)
      @subscriber = @policy.subscriber.person

      @notice = PdfTemplates::IrsNoticeInput.new

      @notice.issuer_name = @policy.plan.carrier.name
      @notice.policy_id = @policy.eg_id
      @notice.has_aptc = true if @policy.applied_aptc > 0
      @notice.recipient_address = PdfTemplates::NoticeAddress.new(address_to_hash(@subscriber.addresses[0]))
 
      append_policy_enrollees
      append_monthly_premiums
    end

    def append_policy_enrollees
      @notice.recipient = build_enrollee_ele(@policy.subscriber)
      @notice.spouse = build_enrollee_ele(@policy.spouse)
      @notice.covered_household = @policy_disposition.enrollees.map{ |enrollee| build_enrollee_ele(enrollee) }.compact
    end

    def build_enrollee_ele(enrollee)
      return nil if enrollee.blank?
      authority_member = enrollee.person.authority_member
      return nil if authority_member.nil?
      coverage_end = enrollee.coverage_end.blank? ? @policy.coverage_period.end : enrollee.coverage_end
      PdfTemplates::Enrolee.new({
        name: enrollee.person.full_name,
        ssn: authority_member.ssn, # 'xxxxxxxxx'
        dob: format_date(authority_member.dob),
        coverage_start_date: format_date(enrollee.coverage_start),
        coverage_termination_date: format_date(coverage_end)
      })
    end

    def append_monthly_premiums
      @notice.monthly_premiums = (@policy_disposition.start_date.month..@policy_disposition.end_date.month).inject([]) do |data, i|
        premium_amounts = {
          serial: i,
          premium_amount: @policy_disposition.as_of(Date.new(IRS_YEAR, i, 1)).ehb_premium
        }

        if @policy.applied_aptc > 0
          calc = Premiums::PolicyCalculator.new
          silver_plan = Plan.where({ "year" => 2014, "hios_plan_id" => "86052DC0400001-01" }).first
          silver_plan_premium = @policy_disposition.as_of(Date.new(IRS_YEAR, i, 1), silver_plan).ehb_premium

          premium_amounts.merge!({
            premium_amount_slcsp: silver_plan_premium,
            monthly_aptc: @policy_disposition.as_of(Date.new(IRS_YEAR, i, 1)).applied_aptc
          })
        end

        data << premium_amounts
      end
    end

    private

    def format_date(date)
      return nil if date.blank?
      date.strftime("%m/%d/%Y")
    end

    def address_to_hash(address)
      {
        street_1: address.address_1,
        street_2: address.address_2,
        city: address.city,
        state: address.state,
        zip: address.zip
      }
    end
  end
end