module EmployerContributions
  class FederalEmployer < Strategy
    field :contribution_percent, type: BigDecimal

    embeds_many :federal_contribution_groups, :class_name => "::EmployerContributions::FederalContributionGroup"
  end
end
