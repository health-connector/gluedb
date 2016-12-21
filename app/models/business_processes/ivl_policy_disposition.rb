module BusinessProcesses
  class IvlPolicyDisposition
    include Handlers::EnrollmentEventXmlHelper

    attr_reader :enrollment_event_cv, :policy_cv
    def initialize(e_event_cv, p_cv)
      @enrollment_event_cv = e_event_cv
      @policy_cv = p_cv
    end

    def processable_kind?
      false
    end

    def change_kind
      @change_kind ||= extract_enrollment_action(enrollment_event_cv)
    end

    def renewal_candidates
      @renewal_candidates ||= begin
                                plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
                                return [] if subscriber_person.nil?
                                subscriber_person.policies.select do |pol|
                                  ivl_renewal_candidate?(pol, plan, subscriber_id, subscriber_start)
                                end
                              end
    end

    def policy_action
      # Determine and provide correct action here
    end

    def member_count_change?
    end

    def terminations
      [plan, subscriber_person, subscriber_id, subscriber_start] = extract_policy_details
      return [] if subscriber_person.nil?
      terms = []
      if renewal_candidates.any?
        renewal_candidates.each do |rc|
          # Add a termination for the old carrier for each switch
          if plan.carrier_id != rc.plan.carrier_id
            terms << BusinessProcess::EnrollmentTermination.new(rc.eg_id, subscriber_start - 1.day, c_pol.active_member_ids)
          end  
        end
      end
      if competing_policies.any?
        competing_policies.each do |c_pol|
          # Terminate the enrollment - transmit ONLY if different carrier
          if c_pol.coverage_period.start < subscriber_start
            term = BusinessProcess::EnrollmentTermination.new(rc.eg_id, subscriber_start - 1.day, c_pol.active_member_ids)
            if plan.carrier_id == rc.plan.carrier_id
              term.transmit = false
            end
            terms << term
          end
        end
      end
      terms
    end

    def cancels
      return [] if !competing_policies.any?
      [plan, subscriber_person, subscriber_id, subscriber_start] = extract_policy_details
      return [] if subscriber_person.nil?
      cancel_pols = []
      if competing_policies.any?
        competing_policies.each do |c_pol|
          # cancel the enrollment - transmit ONLY if different carrier
          if c_pol.coverage_period.start == subscriber_start
            cancellation = BusinessProcess::EnrollmentCancellation.new(c_pol.eg_id, c_pol.active_member_ids)
            if plan.carrier_id == c_pol.plan.carrier_id
              term.transmit = false
            end
            cancel_pols << cancellation
          end
        end
      end
      cancel_pols
    end

    def competing_policies
      @competing_policies ||= competing_ivl_coverage(enrollment_event_cv, policy_cv)
    end

    def bogus_ivl_renewal?
      return false unless is_ivl_passive_renewal?
      plan, subscriber_person, subscriber_id, subscriber_start = extract_policy_details
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

    def extract_policy_details
      @policy_details ||=
        begin
          subscriber_enrollee = extract_subscriber(policy_cv)
          subscriber_id = extract_member_id(subscriber_enrollee)
          subscriber_start = extract_enrollee_start(subscriber_enrollee)
          plan = extract_plan(policy_cv)
          coverage_type = plan.coverage_type
          subscriber_person = Person.find_by_member_id(subscriber_id)
          [plan, subscriber_person, subscriber_id, subscriber_start]
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
      (pol.coverage_period.end == (subscriber_start - 1.day))
    end
  end
end
