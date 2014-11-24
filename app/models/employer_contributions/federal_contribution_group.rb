module EmployerContributions
  class FederalContributionGroup
    include Mongoid::Document

    embedded_in :federal_employer, :class_name => "::EmployerContributions::FederalEmployer"

    field :enrollee_count, type: Integer
    field :contribution_amount, type: BigDecimal
  end
end
