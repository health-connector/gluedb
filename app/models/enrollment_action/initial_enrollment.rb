module EnrollmentAction
  class InitialEnrollment < Base
    extend RenewalComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      !any_renewal_candidates?(chunk.first)
    end
  end
end
