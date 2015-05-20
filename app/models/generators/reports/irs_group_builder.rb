module Generators::Reports 
  class IrsGroupBuilder

    attr_accessor :irs_group, :calender_year, :carrier_hash

    def initialize(family)
      @family = family
      @irs_group = PdfTemplates::IrsGroup.new
      @carrier_hash = {}
    end

    def process
      @irs_group.identification_num = @family.irs_groups.first.hbx_assigned_id
      @irs_group.calender_year = @calender_year
      build_households
      build_insurance_policies
    end

    def build_insurance_policies
      pols = get_valid_policies(@irs_group.coverage_ids)

      if pols.empty?
        raise 'No valid policies to report!!'
      end

      @irs_group.policies = pols
      @irs_group.insurance_policies = pols.inject([]) do |data, pol| 
        data << build_policy(pol)
      end
    end

    def build_policy(pol)
      builder = Generators::Reports::IrsInputBuilder.new(pol)
      builder.carrier_hash = @carrier_hash
      builder.process
      builder.notice
    end

    # Lets assume we have only one household
    def build_households
      households = []

      @family.households.each do |household|
        if household.has_aptc?(@calender_year)
          households << build_household_for_aptc(household)
        else
          households << build_household_for_nonaptc(household)
        end
      end

      @irs_group.households = households
    end

    def build_household_for_aptc(household)
      tax_households = household.tax_households.inject([]) do |tax_households, tax_household|        
        tax_households << build_tax_household(tax_household)
      end

      PdfTemplates::Household.new({
        tax_households: tax_households,
        has_aptc: true
        })
    end

    def build_household_for_nonaptc(household)
      coverage_households = []

      household.policy_coverage_households(@calender_year).each do |coverage_household|
        coverage_households << PdfTemplates::CoverageHousehold.new({
          primary: build_enrollee(coverage_household[:primary], true),
          policy_ids: coverage_household[:policy_ids]
          })
      end

      PdfTemplates::Household.new({
        coverage_households: coverage_households
        }) 
    end

    def build_tax_household(tax_household)
      PdfTemplates::TaxHousehold.new({
        primary: build_tax_member(tax_household.primary, true),
        spouse:  build_tax_member(tax_household.spouse), 
        dependents: tax_household.dependents.map{ |dependent| build_tax_member(dependent) },
        policy_ids: tax_household.coverage_as_of(Date.new(2014, month, 1))
        })
    end

    def build_tax_member(household_member, is_primary = false)
      return if household_member.blank?
      person = household_member.family_member.person

      build_enrollee(person, is_primary)
    end

    def build_enrollee(person, is_primary)
      member = person.authority_member
      return if member.blank?

      PdfTemplates::Enrollee.new({
        name: person.full_name,
        ssn: member.ssn,
        dob: format_date(member.dob),
        name_first: person.name_first,
        name_middle: person.name_middle,
        name_last: person.name_last,
        name_sfx: person.name_sfx,
        address: build_address(person, is_primary)
        })
    end

    def build_address(person, is_primary)
      address = person.addresses[0]
      address ||= @primary_address

      if is_primary
        if address.nil?
          raise 'Primary address missing'
        else
          @primary_address = address
        end
      end

      PdfTemplates::NoticeAddress.new({
        street_1: address.address_1,
        street_2: address.address_2,
        city: address.city,
        state: address.state,
        zip: address.zip
      })
    end

    # def build_insurance_policies
    #   pols = get_valid_policies(@irs_group.policy_ids)
    #   if pols.empty?
    #     raise 'No valid policies to report!!'
    #   end

    #   @irs_group.insurance_policies = pols.inject([]) do |data, pol| 
    #     data << Generators::Reports::IrsInputBuilder.new(pol).notice
    #   end
    # end
    
    # def build_taxhouseholds
    #   tax_households = []

    #   @family.households.each do |household| 
    #     if @family.has_aptc?(@calender_year)
    #       tax_households << household.tax_households
    #     else
    #       tax_households << household.irs_coverage_households
    #     end
    #   end

    #   tax_households.flatten!
    #   @irs_group.tax_households = tax_households.inject([]) do |data, tax_household| 
    #     data << build_taxhousehold(tax_household)
    #   end
    # end

    # def build_taxhousehold(tax_household)
    #   coverages = (1..@months).inject([]) do |data, month| 
    #     data << build_household_coverage(tax_household, month)
    #   end

    #   PdfTemplates::TaxHousehold.new({
    #     tax_household_coverages: coverages
    #   })    
    # end

    # def build_household_coverage(tax_household, month)
    #   PdfTemplates::TaxHouseholdCoverage.new({
    #     calender_month: month,
    #     primary: build_tax_member(tax_household.primary, true),
    #     spouse: build_tax_member(tax_household.spouse), 
    #     dependents: tax_household.dependents.map{ |dependent| build_tax_member(dependent) },
    #     policy_ids: tax_household.coverage_as_of(Date.new(2014, month, 1))
    #   })
    # end

  
    # Implement for SHOP  
    def build_employer_mec(employer)
    end

    private

    def get_valid_policies(policy_ids)
      pols = policy_ids.inject([]) {|pols, id| pols << Policy.find(id)}
      pols.reject!{|pol| pol.rejected?}
      pols.reject!{|pol| pol.has_no_enrollees?}
      pols.reject!{|pol| !pol.belong_to_year?(@calender_year) }
      pols
    end

    def format_date(date)
      return nil if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end
