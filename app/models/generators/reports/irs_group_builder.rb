module Generators::Reports  
  class IrsGroupBuilder

    attr_accessor :irs_group

    def initialize(family)
      @family = family
      @irs_group = PdfTemplates::IrsGroup.new
    end

    def process
      build_households
      build_associated_policies
    end

    # NEED TO IMPLEMENT
    def valid_households
      if @family.households.count > 1
        @family.households      
      else
        @family.households
      end
    end

    # TODO: WHAT IF TWO HOUSEHOLDS CREATED IN SAME MONTH
    def build_households
      households = []

      valid_households.each do |household| 
        households << build_household(household)
      end

      @irs_group.households = households
    end

    def build_associated_policies
      tax_households = @irs_group.households.map{|x| x.tax_households}
      policies = tax_households.flatten.inject([]) do |data, tax_household|
        data << tax_household.policies
      end
      pols = get_valid_policies(policies.flatten.uniq)
      if pols.empty?
        raise 'No valid policies to report!!'
      end

      @irs_group.policies = pols.inject([]){|data, pol| data << Generators::Reports::IrsInputBuilder.new(pol)}
    end

    def build_household(household)
      tax_households = []

      household.tax_households.each do |tax_household|
        tax_households << build_tax_household(tax_household)
      end

      if tax_households.empty?
        tax_households << build_tax_household(household.coverage_households[0])
      end

      PdfTemplates::Household.new({
        tax_households: tax_households
        })
    end

    def build_tax_household(tax_household)
      PdfTemplates::TaxHousehold.new({
        primary: build_tax_member(tax_household.primary),
        spouse: build_tax_member(tax_household.spouse), 
        dependents: tax_household.dependents.map{|dependent| build_tax_member(dependent)},
        policies: build_tax_household_pols(tax_household)
        })
    end

    def build_tax_member(household_member)
      return nil if household_member.nil?
      person = household_member.family_member.person
      return nil if person.authority_member.nil?
      PdfTemplates::Enrollee.new({
        name: person.full_name,
        ssn: person.authority_member.ssn,
        dob: format_date(person.authority_member.dob),
        address: build_address(household_member)
        })
    end

    def build_tax_household_pols(tax_household)
      (1..12).inject({}) do |data, i|
        data[i] = tax_household.coverage_as_of(Date.new(2014, i, 1))
        data
      end
    end

    def build_address(household_member)
      address = household_member.family_member.person.addresses[0]
      if address.nil?
        primary_member = household_member.kind_of?(TaxHouseholdMember) ? household_member.tax_household.primary : household_member.coverage_hosuehold.primary
        address = primary_member.family_member.person.addresses[0]
      end

      PdfTemplates::NoticeAddress.new({
        street_1: address.address_1,
        street_2: address.address_2,
        city: address.city,
        state: address.state,
        zip: address.zip
        })
    end

    def build_employer_mec(employer)
      nil
    end

    def get_valid_policies(pols)
      pols.reject!{|pol| pol.rejected?}
      pols.reject!{|pol| pol.has_no_enrollees?}
      pols
    end

    private

    def format_date(date)
      return nil if date.blank?
      date.strftime("%m/%d/%Y")
    end
  end
end