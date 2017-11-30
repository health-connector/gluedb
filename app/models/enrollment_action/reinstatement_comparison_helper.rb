module EnrollmentAction
  module ReinstatementComparisonHelper
    include Handlers::EnrollmentEventXmlHelper

    def same_carrier_reinstatement_candidates(enrollment_event)
      shop_reinstatement_candidates(enrollment_event.policy_cv)
    end

    def shop_reinstatement_candidates(policy_cv)
      subscriber_enrollee = extract_subscriber(policy_cv)
      subscriber_start = extract_enrollee_start(subscriber_enrollee)
      subscriber_id = extract_member_id(subscriber_enrollee)
      subscriber_person = Person.find_by_member_id(subscriber_id)
      employer = find_employer(policy_cv)
      plan_year = find_employer_plan_year(policy_cv)
      return [] if subscriber_person.nil?
      plan = extract_plan(policy_cv)
      subscriber_person.policies.select do |pol|
        shop_reinstatement_candidate?(pol, plan, employer, subscriber_id, subscriber_start)
      end
    end

    def shop_reinstatement_candidate?(pol, plan, employer, subscriber_id, subscriber_start)
      return false if pol.employer_id.blank?
      return false if pol.subscriber.blank?
      return false if (pol.subscriber.m_id != subscriber_id)
      return false unless (plan.coverage_type == pol.plan.coverage_type)
      return false unless (pol.employer_id == employer.id)
      return false unless (plan.year == pol.plan.year)
      return false unless (plan.carrier_id == pol.plan.carrier_id) 
      pol.coverage_period.end == subscriber_start - 1.day
    end
  end
end
