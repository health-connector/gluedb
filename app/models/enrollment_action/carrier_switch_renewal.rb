module EnrollmentAction
  class CarrierSwitchRenewal < Base
    extend RenewalComparisonHelper
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      renewal_candidates = other_carrier_renewal_candidates(chunk.first)
      !renewal_candidates.empty?
    end
  end
end
