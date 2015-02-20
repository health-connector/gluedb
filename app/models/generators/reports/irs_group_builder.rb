module Generators::Reports  
  class IrsGroupBuilder

    attr_accessor :irs_group

    CALENDER_YEAR = 2014

    def initialize(family, months)
      @family = family
      @months = months
      @irs_group = PdfTemplates::IrsGroup.new
    end

    def process
      @irs_group.identification_num = @family.irs_groups.first.hbx_assigned_id
      build_taxhouseholds
      build_insurance_policies
    end

    def build_insurance_policies
      pols = get_valid_policies(@irs_group.policy_ids)
      if pols.empty?
        raise 'No valid policies to report!!'
      end

      @irs_group.insurance_policies = pols.inject([]) do |data, pol| 
        data << Generators::Reports::IrsInputBuilder.new(pol).notice
      end
    end
    
    def build_taxhouseholds
      tax_households = []

      @family.households.each do |household| 
        if @family.has_aptc?(CALENDER_YEAR)
          tax_households << household.tax_households
        else
          tax_households << household.coverage_households
        end
      end

      tax_households.flatten!
      @irs_group.tax_households = tax_households.inject([]) do |data, tax_household| 
        data << build_taxhousehold(tax_household)
      end
    end

    def build_taxhousehold(tax_household)
      coverages = (1..@months).inject([]) do |data, month| 
        data << build_household_coverage(tax_household, month)
      end

      PdfTemplates::TaxHousehold.new({
        tax_household_coverages: coverages
      })    
    end

    def build_household_coverage(tax_household, month)
      PdfTemplates::TaxHouseholdCoverage.new({
        calender_month: month,
        primary: build_tax_member(tax_household.primary, true),
        spouse: build_tax_member(tax_household.spouse), 
        dependents: tax_household.dependents.map{ |dependent| build_tax_member(dependent) },
        policy_ids: tax_household.coverage_as_of(Date.new(2014, month, 1))
      })
    end

    def build_tax_member(household_member, is_primary = false)
      return if household_member.blank?

      person = household_member.family_member.person
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
        address: build_address(household_member, is_primary)
      })
    end

    def build_address(household_member, is_primary)
      address = household_member.family_member.person.addresses[0]
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

    # Implement for SHOP  
    def build_employer_mec(employer)
    end

    private

    def get_valid_policies(policy_ids)
      pols = policy_ids.inject([]) {|pols, id| pols << Policy.find(id)}
      pols.reject!{|pol| pol.rejected?}
      pols.reject!{|pol| pol.has_no_enrollees?}
      pols
    end

    def format_date(date)
      return nil if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end