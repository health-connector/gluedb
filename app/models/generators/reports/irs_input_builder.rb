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
      @notice.policy_id = prepend_zeros(@policy.id.to_s, 6)
      @notice.has_aptc = true if @policy.applied_aptc > 0
      @notice.recipient_address = PdfTemplates::NoticeAddress.new(address_to_hash(@subscriber.addresses[0]))
 
      append_policy_enrollees
      append_monthly_premiums
      append_yearly_premiums
      reset_variables
    end

    def reset_variables
      @policy_disposition = nil
      @subscriber = nil
      @policy = nil
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
        ssn: number_to_ssn(authority_member.ssn),
        dob: format_date(authority_member.dob),
        coverage_start_date: format_date(enrollee.coverage_start),
        coverage_termination_date: format_date(coverage_end),
        name_first: enrollee.person.name_first,
        name_middle: enrollee.person.name_middle,
        name_last: enrollee.person.name_last,
        name_sfx: enrollee.person.name_sfx
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

    def append_yearly_premiums
      yearly_premium = {
        premium_amount: @notice.monthly_premiums.inject(0.0){|sum, premium|  sum + premium.premium_amount.to_f}
      }

      slcsp_amount = @notice.monthly_premiums.inject(0.0){|sum, premium| sum + premium.premium_amount_slcsp.to_f}
      aptc_amount = @notice.monthly_premiums.inject(0.0){|sum, premium| sum + premium.monthly_aptc.to_f}

      if @policy.applied_aptc > 0
        yearly_premium.merge!({
          slcsp_premium_amount: slcsp_amount,
          aptc_amount: aptc_amount
        })
      end

      @notice.yearly_premium = PdfTemplates::YearlyPremium.new(yearly_premium)
    end

    private

    def format_date(date)
      return nil if date.blank?
      date.strftime("%m/%d/%Y")
    end

    def number_to_ssn(number)
      return unless number
      delimiter = "-"
      number.to_s.gsub!(/(\d{0,3})(\d{2})(\d{4})$/,"\\1#{delimiter}\\2#{delimiter}\\3")
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

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end
  end
end