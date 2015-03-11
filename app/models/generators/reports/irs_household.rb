module Generators::Reports  
  class IrsHousehold

    attr_accessor :calender_year, :tax_households, :tax_household_objs

    def initialize(household)
      @household = household
      @calender_year = nil
      @tax_households = []
      @tax_household_objs = []
    end

    def process
      @tax_households = @household.tax_households

      if @household.tax_households.count > 1
        tax_households_hash = @household.tax_households.inject({}) do |tax_households, tax_household|
          member_hash = tax_household.tax_household_members.inject({}) do |members_with_financials, member|
            members_with_financials[member.applicant_id] = member.tax_filing_status
            members_with_financials
          end
          tax_households.delete_if{|key,val| val == member_hash}
          tax_households[tax_household] = member_hash
          tax_households
        end
        @tax_households = tax_households_hash.keys
      end

      build_irs_tax_households
    end

    def build_irs_tax_households
      @tax_households.each do |tax_household|
        irs_tax_household = Generators::Reports::IrsTaxHousehold.new(tax_household)
        irs_tax_household.calender_year = @calender_year
        @tax_household_objs << irs_tax_household.build
      end
    end

  end
end