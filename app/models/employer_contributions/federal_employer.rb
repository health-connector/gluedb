module EmployerContributions
  class FederalEmployer < Strategy
    field :contribution_percent, type: BigDecimal

    embeds_many :federal_contribution_groups, :class_name => "::EmployerContributions::FederalContributionGroup"

    validates_presence_of :contribution_percent

    def applicable_group_for(enrollment)
      people_count = enrollment.enrollees.length
      max_group = federal_contribution_groups.max_by(&:enrollee_count)
      found_group = federal_contribution_groups.detect do |fcg|
        fcg.enrollee_count == people_count
      end
      found_group.blank? ? max_group : found_group
    end

    def max_amount_for(enrollment)
      applicable_group_for(enrollment).contribution_amount.to_f
    end

    def contribution_for(enrollment)
      percent_contribution = enrollment.pre_amt_tot * 0.01000 * contribution_percent.to_f
      (sprintf("%.2f", [percent_contribution, max_amount_for(enrollment)].min)).to_f
    end
  end
end
