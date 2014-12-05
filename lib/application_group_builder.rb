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

  def add_tax_households(tax_households_params)
    tax_households = tax_households_params.map do |tax_household_params|
      TaxHousehold.new(tax_household_params)
    end

    household = Household.new
    household.tax_households = tax_households
    @application_group.households << household
  end

end