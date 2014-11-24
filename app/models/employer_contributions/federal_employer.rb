module EmployerContributions
  class FederalEmployer < Strategy
    field :contribution_percent, type: BigDecimal

    embeds_many :federal_contribution_groups, :class_name => "::EmployerContributions::FederalContributionGroup"

    validates_presence_of :contribution_percent
  end
end
