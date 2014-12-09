class ApplicationGroupBuilder

  attr_reader :application_group

  def initialize(param, person_mapper)
    param = param.slice('e_case_id', 'submitted_date')
    @person_mapper = person_mapper
    @application_group = ApplicationGroup.new(param)
    @household = self.application_group.households.build
  end

  def add_applicant(applicant_params)
    applicant = @application_group.applicants.build(applicant_params)
  end


  def add_irsgroups(irs_groups_params)
    irs_groups = irs_groups_params.map do |irs_group_params|
      IrsGroup.new(irs_group_params)
    end

    @application_group.irs_groups = irs_groups

  end

  def add_tax_households(tax_households_params, eligibility_determinations_params)

    tax_households_params.map do |tax_household_params|
      tax_household = @household.tax_households.build(tax_household_params)

      tax_household_params[:tax_household_members].map do |tax_household_member_params|
        #tax_household_member = TaxHouseholdMember.new(tax_household_member_params)
        tax_household_member = tax_household.tax_household_members.build(tax_household_member_params)
        #tax_household_member.applicant_id = @person_mapper.get_applicant(tax_household_member_params[:id]).id
        puts "MY SEARRCH KEY #{tax_household_member_params[:id]}"
        person_uri =  @person_mapper.alias_map[tax_household_member_params[:id]]
        person_obj = @person_mapper.people_map[person_uri].first
        tax_household_member.applicant_id = @person_mapper.applicant_map[person_obj.id].id
        tax_household_member.applicant = @person_mapper.applicant_map[person_obj.id]
        #puts tax_household_member.application_group.inspect
        # tax_household.tax_household_members.build(tax_household_member)
      end

      #puts @household.tax_households.flat_map(&:tax_household_members).flat_map(&:applicant).inspect

    end


    eligibility_determinations_params.each do |eligibility_determination_params|
      #TODO assuming only 1tax_household. needs to be corrected later
      eligibility_determination = EligibilityDetermination.new(eligibility_determination_params)
      @household.tax_households.first.eligibility_determinations << eligibility_determination
    end

  end

  def add_financial_statements(applicants_params)

    applicants_params.map do |applicant_params|
      applicant_params[:financial_statements].each do |financial_statement_params|
        tax_household_member = find_tax_household_member(@person_mapper.applicant_map[applicant_params[:person].id])
        financial_statement = tax_household_member.financial_statements.build(financial_statement_params)
        financial_statement_params[:incomes].each do |income_params|
          financial_statement.incomes.build(income_params)
        end
        financial_statement_params[:deductions].each do |deduction_params|
          financial_statement.deductions.build(deduction_params)
        end
        financial_statement_params[:alternative_benefits].each do |alternative_benefit_params|
          financial_statement.alternative_benefits.build(alternative_benefit_params)
        end
      end
    end

=begin
    applicants_params.map do |applicant_params|
      applicant_params[:financial_statements].each do |financial_statement_params|
        #financial_statement = FinancialStatement.new(financial_statement_params)
        financial_statement = @household.FinancialStatement.new(financial_statement_params)
        financial_statement.incomes << financial_statement_params[:incomes].map do |income_params|
          income = Income.new(income_params)
        end
        financial_statement.deductions << financial_statement_params[:deductions].map do |deduction_params|
          Deduction.new(deduction_params)
        end
        add_financial_statements_to_tax_household(financial_statement, applicant_params[:id])
      end
    end
=end
  end

  def find_tax_household_member(applicant)
    tax_household_members = self.application_group.households.flat_map(&:tax_households).flat_map(&:tax_household_members)

    tax_household_member = tax_household_members.find do |tax_household_member|

      tax_household_member.applicant_id == applicant.id
    end

    tax_household_member
  end

  def add_financial_statements_to_tax_household(financial_statement, applicant_id)
      tax_household_members = self.application_group.households.flat_map(&:tax_households).flat_map(&:tax_household_members)

      tax_household_member = tax_household_members.find do |tax_household_member|
        puts applicant_id
        puts tax_household_member.inspect
        tax_household_member.applicant_id = applicant_id
      end

      tax_household_member.financial_statements << financial_statement if tax_household_member
  end

end