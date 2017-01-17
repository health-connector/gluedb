module EnrollmentAction
  module RenewalComparisonHelper
    def any_renewal_candidates?(enrollment_event)
      (same_carrier_renewal_candidates(enrollment_event).any? ||
        other_carrier_renewal_candidates(enrollment_event).any?)
    end

    def same_carrier_renewal_candidates(enrollment_event)
      []
    end

    def other_carrier_renewal_candidates(enrollment_event)
      []
    end

    def renewal_dependents_changed?(renewal_candidate, enrollment_event)
    end

    def renewal_dependents_added?(renewal_candidate, enrollment_event)
    end

    def renewal_dependents_dropped?(renewal_candidate, enrollment_event)
    end
  end
end
