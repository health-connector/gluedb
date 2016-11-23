module Handlers
  class EnrichHandler < Base
    include EnrollmentEventXmlHelper

    def call(context)
      event_list = merge_or_split(context, context.event_list)
      if !context.errors.has_errors?
        event_list.map do |element|
          super(duplicate_context(context, element))
        end
      else
        [context]
      end
    end

    protected
    def duplicate_context(context, event_xml)
      new_context = context.clone
      new_context.event_message = event_xml
      new_context
    end

    def merge_or_split(context, event_list)
      last_event = event_list.last.event_xml
      enrollment_event_cv = enrollment_event_cv_for(last_event)
      policy_cv = extract_policy(enrollment_event_cv)
      if event_list.length > 1
        context.errors.add(:process, "These events represent a compound event flow, and we don't handle that yet.")
        return []
      end
      if already_exists?(policy_cv)
        context.errors.add(:process, "The enrollment to create already exists")
        return []
      end
      if determine_market(enrollment_event_cv) == "shop"
        context.errors.add(:process, "We don't currently process shop")
        return []
      end
      if competing_coverage(policy_cv).any?
        context.errors.add(:process, "We found competing coverage for this enrollment.  We don't currently process that.")
        return []
      end
      event_list
    end

    def already_exists?(policy_cv)
      enrollment_group_id = extract_enrollment_group_id(policy_cv)
      Policy.where(:eg_id => enrollment_group_id).any?
    end

    def competing_coverage(policy_cv)
      subscriber_enrollee = extract_subscriber(policy_cv)
      subscriber_id = extract_member_id(subscriber_enrollee)
      subscriber_start = extract_enrollee_start(subscriber_enrollee)
      plan = extract_plan(policy_cv)
      coverage_type = plan.coverage_type
      subscriber_person = Person.find_by_member_id(subscriber_id)
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
      pol.subscriber.coverage_end < subscriber_start
    end
  end
end
