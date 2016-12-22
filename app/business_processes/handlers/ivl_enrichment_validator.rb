module Handlers
  class IvlEnrichmentValidator
    include EnrollmentEventXmlHelper

    attr_reader :errors, :enrollment_event_cv, :policy_cv, :last_event
    def initialize(errs, e_event_cv, p_cv, l_event)
      @errors = errs
      @enrollment_event_cv = e_event_cv
      @policy_cv = p_cv
      @last_event = l_event
    end

    def valid?
      policy_disposition = ::BusinessProcesses::IvlPolicyDisposition.new(enrollment_event_cv, policy_cv)
      if policy_disposition.members_changed?
        errors.add(:process, "It seems the member composition has changed.  We don't currently process that.")
        errors.add(:process, last_event)
        return false
      end
      if policy_disposition.bogus_ivl_renewal?
        errors.add(:process, "This enrollment is marked as a renewal, but doesn't have active coverage for the preceeding year.")
        errors.add(:process, last_event)
        return false
      end
      if invalid_ivl_plan_year?(enrollment_event_cv, policy_cv)
        errors.add(:process, "This enrollment has a set of coverage dates which don't match the active year of the plan.")
        errors.add(:process, last_event)
        return false
      end
      true
    end

    def invalid_ivl_plan_year?(enrollment_event_cv, policy_cv)
      subscriber_enrollee = extract_subscriber(policy_cv)
      return false unless subscriber_enrollee
      subscriber_start = extract_enrollee_start(subscriber_enrollee)
      plan = extract_plan(policy_cv)
      subscriber_start.year != plan.year
    end
  end
end
