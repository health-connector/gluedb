module EnrollmentAction
  class RenewalDependentAdd < Base
    extend RenewalComparisonHelper

    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      renewal_candidates = same_carrier_renewal_candidates(chunk.first)
      return false if renewal_candidates.empty?
      renewal_dependents_added?([renewal_candidates.first, chunk.first])
    end
  end
end
