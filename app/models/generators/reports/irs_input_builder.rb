module Generators::Reports  
  class IrsInputBuilder

    attr_accessor :notice, :carrier_hash
 
    IRS_YEAR = 2014

    SLCSP_CORRECTIONS = {
      7884 => 721.07,
      8269 => 396.61, 
      8393 => 480.38, 
      12236 => 743.3, 
      15585 => 575.26, 
      15824 => 486.55, 
      19846 => 216.47
    }

    def initialize(policy, options = {})
      multi_version = options[:multi_version] || false
      @void = options[:void] || false
      @carrier_hash = {}
      @policy = policy
      @policy_disposition = PolicyDisposition.new(policy)
      @subscriber = @policy.subscriber.person

      if multi_version
        @multi_version_pol = Generators::Reports::MultiVersionAptcLookup.new(policy)
      end
    end

    def process
      @notice = PdfTemplates::IrsNoticeInput.new
      @notice.issuer_name = @carrier_hash[@policy.carrier_id]
      # @policy.plan.carrier.name
      @notice.qhp_id = @policy.plan.hios_plan_id.gsub('-','')
      @notice.policy_id = prepend_zeros(@policy.id.to_s, 6)
      # @notice.has_aptc = true if @policy.applied_aptc > 0
      
      @notice.recipient_address = PdfTemplates::NoticeAddress.new(address_to_hash(@subscriber.addresses[0]))

      append_policy_enrollees
      @void ? append_void_monthly_premiums : append_monthly_premiums

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
      @notice.covered_household = @policy_disposition.enrollees.map{ |enrollee| build_enrollee_ele(enrollee) }.compact unless @void
    end

    def build_enrollee_ele(enrollee)
      return nil if enrollee.blank?
      authority_member = enrollee.person.authority_member
      return nil if authority_member.nil?
      coverage_end = enrollee.coverage_end.blank? ? @policy.coverage_period.end : enrollee.coverage_end
      PdfTemplates::Enrollee.new({
        name: enrollee.person.full_name,
        ssn: authority_member.ssn,
        dob: format_date(authority_member.dob),
        coverage_start_date: format_date(enrollee.coverage_start),
        coverage_termination_date: format_date(coverage_end),
        name_first: enrollee.person.name_first,
        name_middle: enrollee.person.name_middle,
        name_last: enrollee.person.name_last,
        name_sfx: enrollee.person.name_sfx
      })
    end

    def append_void_monthly_premiums
      @notice.monthly_premiums = 12.times.inject([]) do |monthly_premiums, index|
        monthly_premiums << {
          serial: (index + 1),
          premium_amount: 0.0,
          premium_amount_slcsp: 0.0,
          monthly_aptc: 0.0          
        }
      end
    end

    def append_monthly_premiums
      coverage_end_month = @policy_disposition.end_date.month
      coverage_end_month = coverage_end_month - 1 if (@policy_disposition.end_date.day == 1)

      if @policy_disposition.end_date.year != IRS_YEAR
        coverage_end_month = 12
      end

      @notice.monthly_premiums = (@policy_disposition.start_date.month..coverage_end_month).inject([]) do |data, i|
        premium_amounts = {
          serial: i,
          premium_amount: @policy_disposition.as_of(Date.new(IRS_YEAR, i, 1)).ehb_premium
        }

        @notice.has_aptc = if @multi_version_pol
          true # @multi_version_pol.assisted?
        else
          @policy.applied_aptc > 0
        end

        if @notice.has_aptc
          
          if SLCSP_CORRECTIONS[@policy.id]
            silver_plan_premium = SLCSP_CORRECTIONS[@policy.id]
          else
            silver_plan = Plan.where({ "year" => 2014, "hios_plan_id" => "86052DC0400001-01" }).first
            silver_plan_premium = @policy_disposition.as_of(Date.new(IRS_YEAR, i, 1), silver_plan).ehb_premium
          end

          aptc_amt = @multi_version_pol.nil? ? 
          @policy_disposition.as_of(Date.new(IRS_YEAR, i, 1)).applied_aptc :
          @multi_version_pol.aptc_as_of(Date.new(IRS_YEAR, i, 1))

          premium_amounts.merge!({
            premium_amount_slcsp: silver_plan_premium,
            monthly_aptc: aptc_amt
          })
        end

        data << ((@notice.has_aptc && premium_amounts[:monthly_aptc].nil?) ? nil : premium_amounts)
      end

      @notice.monthly_premiums.compact!
    end

    def append_yearly_premiums
      yearly_premium = {
        premium_amount: @notice.monthly_premiums.inject(0.0){|sum, premium|  sum + premium.premium_amount.to_f}
      }

      slcsp_amount = @notice.monthly_premiums.inject(0.0){|sum, premium| sum + premium.premium_amount_slcsp.to_f}
      aptc_amount = @notice.monthly_premiums.inject(0.0){|sum, premium| sum + premium.monthly_aptc.to_f}

      if @notice.has_aptc
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