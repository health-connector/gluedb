module Handlers
  class ShopEnrichmentValidator
    include EnrollmentEventXmlHelper

    attr_reader :errors, :enrollment_event_cv, :policy_cv, :last_event
    def initialize(errs, e_event_cv, p_cv, l_event)
      @errors = errs
      @enrollment_event_cv = e_event_cv
      @policy_cv = p_cv
      @last_event = l_event
    end

    def valid?
      errors.add(:process, "We don't currently process shop")
      errors.add(:process, l_event)
      return false
    end

    def invalid_ivl_plan_year?(enrollment_event_cv, policy_cv)
      return false unless is_ivl_renewal?(enrollment_event_cv)
      subscriber_enrollee = extract_subscriber(policy_cv)
      subscriber_start = extract_enrollee_start(subscriber_enrollee)
      plan = extract_plan(policy_cv)
      subscriber_start.year != plan.year
    end

    def extract_policy_details(policy_cv)
      subscriber_enrollee = extract_subscriber(policy_cv)
      subscriber_id = extract_member_id(subscriber_enrollee)
      subscriber_start = extract_enrollee_start(subscriber_enrollee)
      plan = extract_plan(policy_cv)
      coverage_type = plan.coverage_type
      subscriber_person = Person.find_by_member_id(subscriber_id)
      [plan, subscriber_person, subscriber_id, subscriber_start]
    end

    def bogus_ivl_renewal?(enrollment_event_cv, policy_cv)
      return false unless is_ivl_passive_renewal?(enrollment_event_cv)
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details(policy_cv)
      return false if subscriber_person.nil?
      !subscriber_person.policies.any? do |pol|
        ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
      end
    end

    def competing_ivl_coverage(enrollment_event_cv, policy_cv)
      return [] if is_ivl_active_renewal?(enrollment_event_cv)
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details(policy_cv)
      return [] if subscriber_person.nil?
      subscriber_person.policies.select do |pol|
        overlapping_policy?(pol, plan, subscriber_id, subscriber_start)
      end
    end

    def extract_enrollment_action(enrollment_event_cv)
      Maybe.new(enrollment_event_cv).event.body.enrollment.enrollment_type.strip.value
    end

    def is_ivl_active_renewal?(enrollment_event_cv)
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#active_renew"
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    def is_ivl_passive_renewal?(enrollment_event_cv)
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#auto_renew",
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    def is_ivl_renewal?(enrollment_event_cv)
      is_ivl_passive_renewal?(enrollment_event_cv) || is_ivl_active_renewal?(enrollment_event_cv)
    end

    def ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
      return false if pol.is_shop?
      return false unless (pol.plan.year == plan.year - 1)
      return false unless (pol.plan.carrier_id == plan.carrier_id)
      return false unless (plan.coverage_type == pol.plan.coverage_type)
      return false if pol.canceled?
      return false if pol.terminated?
      true
    end

    def overlapping_policy?(pol, plan, subscriber_id, subscriber_start)
      return false if pol.canceled?
      return false if pol.subscriber.blank?
      return false if (pol.subscriber.m_id != subscriber_id)
      return false unless (plan.coverage_type == pol.plan.coverage_type)
      return false unless (plan.year == pol.plan.year)
      return false unless pol.employer_id.blank?
      return true if pol.subscriber.coverage_end.blank?
      !(pol.subscriber.coverage_end < subscriber_start)
    end
  end
end
