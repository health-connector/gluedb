class ApplicationGroupBuilder

  attr_reader :application_group

  def initialize(param)
    @application_group = ApplicationGroup.new(param)
  end

  def add_applicant(applicant)
    @application_group.applicants << applicant
  end

  def add_applicants(applicants)
    @application_group.applicants = applicants
  end

  def add_irsgroups(irs_groups_params)
    irs_groups = irs_groups_params.map do |irs_group_params|
      IrsGroup.new(irs_group_params)
    end

    @application_group.irs_groups = irs_groups

  end

  def add_tax_households(tax_households_params, eligibility_determinations_params)

    #household = self.application_group.households.first | Household.new #TODO currently we assume only 1 household. Appropriate logic to be implemented later.
    tax_households = tax_households_params.map do |tax_household_params|
      tax_household = TaxHousehold.new(tax_household_params)

      tax_household_params[:tax_household_members].map do |tax_household_member|
        tax_household.tax_household_members << TaxHouseholdMember.new(tax_household_member)
      end
    end

    household = Household.new
    household.tax_households << tax_households

    eligibility_determinations_params.each do |eligibility_determination_params|
      puts eligibility_determination_params.inspect
      household.tax_households.first.eligibility_determinations << EligibilityDetermination.new(eligibility_determination_params)
    end

    @application_group.households << household
  end

  def add_financial_statements(applicants_params)
    applicants_params.map do |applicant_params|
      applicant_params[:financial_statements].each do |financial_statement_params|
        financial_statement = FinancialStatement.new(financial_statement_params)
        financial_statement.incomes << financial_statement_params[:incomes].map do |income_params|
          Income.new(income_params)
        end
        financial_statement.deductions << financial_statement_params[:deductions].map do |deduction_params|
          Deduction.new(deduction_params)
        end

        add_financial_statements_to_tax_household(financial_statement, applicant_params[:id])
      end
    end
  end

  def add_financial_statements_to_tax_household(financial_statement, applicant_id)
      tax_household_members = self.application_group.households.flat_map(&:tax_households)#.flat_map(&:tax_household_members)

      tax_household_member = tax_household_members.find do |tax_household_member|
        tax_household_member.applicant_id = applicant_id
      end

      tax_household_member.financial_statements << financial_statement if tax_household_member
  end

end