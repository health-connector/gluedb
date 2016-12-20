module BusinessProcesses
  class IvlPolicyDisposition
    include Handlers::EnrollmentEventXmlHelper

    attr_reader :enrollment_event_cv, :policy_cv
    def initialize(e_event_cv, p_cv)
      @enrollment_event_cv = e_event_cv
      @policy_cv = p_cv
    end

    def processable_kind?
      [].include?(change_kind)
    end

    def change_kind
      @change_kind ||= extract_enrollment_action(enrollment_event_cv)
    end

    def renewal_candidates
      @renewal_candidates ||= begin
                                plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details(policy_cv)
                                return [] if subscriber_person.nil?
                                subscriber_person.policies.select do |pol|
                                  ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
                                end
                              end
    end

    def competing_policies
      @competing_policies ||= competing_ivl_coverage(enrollment_event_cv, policy_cv)
    end

    def bogus_ivl_renewal?(enrollment_event_cv, policy_cv)
      return false unless is_ivl_passive_renewal?(enrollment_event_cv)
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details(policy_cv)
      return false if subscriber_person.nil?
      !renewal_candidates.any?
    end

    def is_ivl_active_renewal?
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#active_renew"
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    def is_ivl_passive_renewal?
      return false if (determine_market(enrollment_event_cv) == "shop")
      [
        "urn:openhbx:terms:v1:enrollment#auto_renew",
      ].include?(extract_enrollment_action(enrollment_event_cv))
    end

    protected

    def extract_policy_details(policy_cv)
      subscriber_enrollee = extract_subscriber(policy_cv)
      subscriber_id = extract_member_id(subscriber_enrollee)
      subscriber_start = extract_enrollee_start(subscriber_enrollee)
      plan = extract_plan(policy_cv)
      coverage_type = plan.coverage_type
      subscriber_person = Person.find_by_member_id(subscriber_id)
      [plan, subscriber_person, subscriber_id, subscriber_start]
    end

    def competing_ivl_coverage(enrollment_event_cv, policy_cv)
      return [] if is_ivl_active_renewal?(enrollment_event_cv)
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details(policy_cv)
      return [] if subscriber_person.nil?
      subscriber_person.policies.select do |pol|
        overlapping_policy?(pol, plan, subscriber_id, subscriber_start)
      end
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

    def ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
      return false if pol.is_shop?
      return false unless (pol.plan.year == plan.year - 1)
      return false unless (pol.plan.carrier_id == plan.carrier_id)
      return false unless (plan.coverage_type == pol.plan.coverage_type)
      return false if pol.canceled?
      return false if pol.terminated?
      true
    end
  end
end
